import math
import struct
import wave
import os
import shutil

def generate_alarm_wav(output_path):
    sample_rate = 44100
    duration = 3.5  # seconds
    num_samples = int(sample_rate * duration)
    
    # Melody notes (frequencies in Hz)
    chimes = [
        (0.0, 0.4, 523.25),  # C5
        (0.2, 0.6, 659.25),  # E5
        (0.4, 0.8, 783.99),  # G5
        (0.6, 1.4, 1046.50), # C6
        
        (1.5, 1.8, 587.33),  # D5
        (1.7, 2.0, 659.25),  # E5
        (1.9, 2.3, 880.00),  # A5
        (2.1, 3.2, 1046.50), # C6 sustain
    ]
    
    samples = [0.0] * num_samples
    
    for start_t, end_t, freq in chimes:
        start_idx = int(start_t * sample_rate)
        end_idx = min(int(end_t * sample_rate), num_samples)
        note_len = end_idx - start_idx
        
        for i in range(note_len):
            t = i / sample_rate
            attack = 0.02
            decay = 0.15
            env = 1.0
            if t < attack:
                env = t / attack
            else:
                remaining_t = t - attack
                env = math.exp(-remaining_t * 3.5)
            
            val = (
                math.sin(2 * math.pi * freq * t) * 0.6 +
                math.sin(2 * math.pi * freq * 2 * t) * 0.25 +
                math.sin(2 * math.pi * freq * 3 * t) * 0.15
            )
            samples[start_idx + i] += val * env * 0.45

    max_val = max(max(abs(s) for s in samples), 0.001)
    scale = 32000 / max_val

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    with wave.open(output_path, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        
        packed_data = bytearray()
        for s in samples:
            sample_val = int(s * scale)
            sample_val = max(-32767, min(32767, sample_val))
            packed_data.extend(struct.pack('<h', sample_val))
        wav_file.writeframes(packed_data)
    print(f"Generated WAV at: {output_path} (Size: {os.path.getsize(output_path)} bytes)")

if __name__ == '__main__':
    # 1. assets/audio/alarm.wav
    generate_alarm_wav('assets/audio/alarm.wav')
    
    # 2. Default C:\DailyFlow folder for Windows
    try:
        os.makedirs(r'C:\DailyFlow', exist_ok=True)
        shutil.copyfile('assets/audio/alarm.wav', r'C:\DailyFlow\alarm.wav')
        print(r"Copied to C:\DailyFlow\alarm.wav")
    except Exception as e:
        print("Could not copy to C:\\DailyFlow:", e)
