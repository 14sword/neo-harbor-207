import os
import logging
from datetime import datetime
from logging.handlers import TimedRotatingFileHandler

class CyberTownLogger:
    """双输出日志系统：控制台 + 文件（按日期分割）"""
    
    def __init__(self, name="cyber_town", log_dir="logs"):
        self.logger = logging.getLogger(name)
        self.logger.setLevel(logging.DEBUG)
        
        if not self.logger.handlers:
            os.makedirs(log_dir, exist_ok=True)
            
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S'
            )
            
            console_handler = logging.StreamHandler()
            console_handler.setLevel(logging.INFO)
            console_handler.setFormatter(formatter)
            self.logger.addHandler(console_handler)
            
            log_file = os.path.join(log_dir, f"cyber_town_{datetime.now().strftime('%Y%m%d')}.log")
            file_handler = TimedRotatingFileHandler(
                log_file,
                when='midnight',
                interval=1,
                backupCount=30,
                encoding='utf-8'
            )
            file_handler.setLevel(logging.DEBUG)
            file_handler.setFormatter(formatter)
            self.logger.addHandler(file_handler)
    
    def get_logger(self):
        return self.logger

logger = CyberTownLogger().get_logger()
