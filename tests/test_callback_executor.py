import psutil
import unittest

from mock import Mock, patch
from patroni.postgresql.callback_executor import CallbackExecutor


class TestCallbackExecutor(unittest.TestCase):

    @patch('psutil.Popen')
    def test_callback_executor(self, mock_popen):
        mock_popen.return_value.children.return_value = []
        mock_popen.return_value.poll.return_value = None

        with patch('patroni.postgresql.callback_executor.terminate_processes', Mock(side_effect=Exception)):
            ce = CallbackExecutor()
            self.assertIsNone(ce.call([]))
            ce.join()

        self.assertIsNone(ce.call([]))

        mock_popen.return_value.kill.side_effect = psutil.AccessDenied()
        self.assertIsNone(ce.call([]))

        ce._process_children = []
        mock_popen.return_value.children.side_effect = psutil.Error()
        mock_popen.return_value.kill.side_effect = psutil.NoSuchProcess(123)
        self.assertIsNone(ce.call([]))

        mock_popen.side_effect = Exception
        ce = CallbackExecutor()
        ce._callback_event.wait = Mock(side_effect=[None, Exception])
        self.assertIsNone(ce.call([]))
        ce.join()
