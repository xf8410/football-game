#!/usr/bin/env python3
"""
TTS语音生成脚本
使用 edge-tts (微软Edge TTS) 生成中文解说语音
如果没有edge-tts，则使用程序化生成的简化语音
"""
import sys
import os
import struct
import math
import wave

def generate_procedural_voice(text: str, output_path: str):
    """
    程序化生成简化解说语音（基于文字长度生成不同音调的语音）
    这不是真正的TTS，但能产生类似解说的声音效果
    """
    sample_rate = 22050
    duration = min(max(len(text) * 0.15, 0.5), 3.0)  # 根据文字长度决定时长
    num_samples = int(sample_rate * duration)

    # 根据文字内容选择音调
    if "进球" in text or "精彩" in text or "世界波" in text:
        base_freq = 400  # 激动的高音
        freq_variation = 100
    elif "犯规" in text or "黄牌" in text or "红牌" in text:
        base_freq = 200  # 严肃的低音
        freq_variation = 30
    elif "角球" in text or "点球" in text:
        base_freq = 300
        freq_variation = 50
    elif "结束" in text:
        base_freq = 250
        freq_variation = 40
    else:
        base_freq = 280
        freq_variation = 60

    # 生成语音波形
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        # 包络（淡入淡出）
        env = 1.0
        if t < 0.05:
            env = t / 0.05
        elif t > duration - 0.1:
            env = (duration - t) / 0.1

        # 基础频率 + 颤音
        freq = base_freq + math.sin(t * 5) * freq_variation
        # 模拟人声的谐波
        wave1 = math.sin(t * freq * 2 * math.pi) * 0.4
        wave2 = math.sin(t * freq * 2 * 2 * math.pi) * 0.2
        wave3 = math.sin(t * freq * 3 * 2 * math.pi) * 0.1
        # 添加噪声模拟辅音
        noise = (os.urandom(1)[0] - 128) / 128.0 * 0.05

        sample = (wave1 + wave2 + wave3 + noise) * env * 0.6
        samples.append(int(sample * 32767))

    # 写入WAV文件
    with wave.open(output_path, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        wav_file.writeframes(struct.pack('<' + 'h' * len(samples), *samples))

    return True

def try_edge_tts(text: str, output_path: str):
    """尝试使用edge-tts生成真正的TTS语音"""
    try:
        import edge_tts
        async def generate():
            communicate = edge_tts.Communicate(text, "zh-CN-XiaoxiaoNeural")
            await communicate.save(output_path.replace('.wav', '.mp3'))
            return True
        import asyncio
        success = asyncio.run(generate())
        if success and os.path.exists(output_path.replace('.wav', '.mp3')):
            # 转换为wav
            os.rename(output_path.replace('.wav', '.mp3'), output_path)
            return True
    except ImportError:
        return False
    except Exception as e:
        print(f"edge-tts error: {e}", file=sys.stderr)
        return False
    return False

def main():
    if len(sys.argv) < 3:
        print("Usage: python3 generate_tts.py <text> <output_path>")
        sys.exit(1)

    text = sys.argv[1]
    output_path = sys.argv[2]

    # 确保输出目录存在
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    # 先尝试edge-tts，失败则用程序化生成
    if try_edge_tts(text, output_path):
        print(f"TTS generated with edge-tts: {output_path}")
    else:
        generate_procedural_voice(text, output_path)
        print(f"TTS generated procedurally: {output_path}")

if __name__ == "__main__":
    main()
