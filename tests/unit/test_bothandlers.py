import unittest
from unittest.mock import AsyncMock, MagicMock
from src.bothandlers.voice_recorder import VoiceRecorder
from datetime import datetime

class TestVoiceRecorder(unittest.TestCase):
    def setUp(self):
        self.client = VoiceRecorder()
        self.client.user = AsyncMock(id=12345)

    def test_voice_state_join(self):
        mock_member = AsyncMock()
        mock_before = AsyncMock(channel=None)
        mock_after = AsyncMock(channel=MagicMock())
        
        self.client.on_voice_state_update(mock_member, mock_before, mock_after)
        self.assertTrue(self.client.recording)
        self.assertIsNotNone(self.client.start_time)

    def test_voice_state_leave(self):
        self.client.recording = True
        self.client.audio_stream = MagicMock()
        self.client.start_time = datetime.now()
        
        mock_member = AsyncMock()
        mock_before = AsyncMock(channel=MagicMock())
        mock_after = AsyncMock(channel=None)
        
        self.client.on_voice_state_update(mock_member, mock_before, mock_after)
        self.assertFalse(self.client.recording)
