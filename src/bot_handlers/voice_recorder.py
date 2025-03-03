import discord
from discord.ext import commands
import datetime

class VoiceRecorder(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
        
    @commands.Cog.listener()
    async def on_voice_state_update(self, member, before, after):
        if before.channel != after.channel:
            print(f"{datetime.datetime.now()} - {member} changed voice channels")

async def setup(bot):
    await bot.add_cog(VoiceRecorder(bot))
