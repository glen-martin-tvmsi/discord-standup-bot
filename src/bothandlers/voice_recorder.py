import discord
import json
from pydub import AudioSegment
from datetime import datetime

class VoiceRecorder(discord.Client):
    def __init__(self):
        super().__init__(intents=discord.Intents.default())
        with open('config/config.json') as f:
            self.config = json.load(f)
        
        self.recording = False
        self.audio_stream = None
        self.start_time = None

    async def on_ready(self):
        print(f'Logged in as {self.user} (ID: {self.user.id})')

    async def on_voice_state_update(self, member, before, after):
        if member == self.user:
            return

        if after.channel and not before.channel:
            if not self.recording:
                self.recording = True
                self.start_time = datetime.now()
                self.audio_stream = await after.channel.connect()
                self.audio_stream.start_recording()
                print(f"Started recording in {after.channel.name}")

        elif before.channel and not after.channel:
            if self.recording:
                self.recording = False
                self.audio_stream.stop_recording()
                filename = f"recording_{self.start_time.strftime('%Y%m%d_%H%M%S')}.wav"
                AudioSegment.from_file(self.audio_stream.save()).export(filename, format="wav")
                await self.audio_stream.disconnect()
                print(f"Saved recording as {filename}")
