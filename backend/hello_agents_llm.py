from openai import OpenAI
from config import settings
from typing import List, Dict, Optional
from logger import logger


class HelloAgentsLLM:
    """LLM 调用封装，三级降级策略：Groq(快速) → MiMo-Flash(中等) → DeepSeek(备用)"""

    PROVIDER_FAST = "groq"
    PROVIDER_MIMO_FLASH = "mimo_flash"
    PROVIDER_MIMO_PRO = "mimo_pro"
    PROVIDER_DEEPSEEK = "deepseek"

    def __init__(self, provider: Optional[str] = None):
        self.provider = provider or "groq"
        self._groq_client = None
        self._mimo_client = None
        self._deepseek_client = None
        self._init_clients()

    def _init_clients(self):
        try:
            self._groq_client = OpenAI(
                api_key=settings.groq_api_key,
                base_url=settings.groq_base_url
            )
        except Exception as e:
            logger.warning(f"Groq client init failed: {e}")

        try:
            self._mimo_client = OpenAI(
                api_key=settings.mimo_api_key,
                base_url=settings.mimo_base_url
            )
        except Exception as e:
            logger.warning(f"MiMo client init failed: {e}")

        try:
            self._deepseek_client = OpenAI(
                api_key=settings.deepseek_api_key,
                base_url=settings.deepseek_base_url
            )
        except Exception as e:
            logger.warning(f"DeepSeek client init failed: {e}")

    def invoke(self, messages: List[Dict], quality: str = "fast") -> str:
        if quality == "high":
            return self._invoke_high_quality(messages)
        elif quality == "batch":
            return self._invoke_batch(messages)
        else:
            return self._invoke_fast(messages)

    def _invoke_fast(self, messages: List[Dict]) -> str:
        if self._groq_client:
            try:
                response = self._groq_client.chat.completions.create(
                    model=settings.groq_model,
                    messages=messages,
                    temperature=0.7,
                    max_tokens=500,
                    timeout=30.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"Groq调用失败，切换MiMo-Flash: {e}")

        if self._mimo_client:
            try:
                response = self._mimo_client.chat.completions.create(
                    model=settings.mimo_flash_model,
                    messages=messages,
                    temperature=0.7,
                    max_tokens=500,
                    timeout=30.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"MiMo-Flash调用失败，切换DeepSeek: {e}")

        if self._deepseek_client:
            try:
                response = self._deepseek_client.chat.completions.create(
                    model=settings.deepseek_model,
                    messages=messages,
                    temperature=0.7,
                    max_tokens=500,
                    timeout=60.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.error(f"DeepSeek也失败了: {e}")
                raise Exception(f"所有LLM调用失败: {str(e)}")

        raise Exception("没有可用的LLM客户端")

    def _invoke_high_quality(self, messages: List[Dict]) -> str:
        if self._mimo_client:
            try:
                response = self._mimo_client.chat.completions.create(
                    model=settings.mimo_pro_model,
                    messages=messages,
                    temperature=0.8,
                    max_tokens=2000,
                    timeout=60.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"MiMo-Pro调用失败，切换DeepSeek: {e}")

        if self._deepseek_client:
            try:
                response = self._deepseek_client.chat.completions.create(
                    model=settings.deepseek_model,
                    messages=messages,
                    temperature=0.8,
                    max_tokens=2000,
                    timeout=60.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"DeepSeek高质量调用失败，尝试Groq: {e}")

        if self._groq_client:
            try:
                response = self._groq_client.chat.completions.create(
                    model=settings.groq_model,
                    messages=messages,
                    temperature=0.8,
                    max_tokens=2000,
                    timeout=30.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.error(f"所有高质量LLM调用失败: {e}")
                raise Exception(f"所有LLM调用失败: {str(e)}")

        raise Exception("没有可用的LLM客户端")

    def _invoke_batch(self, messages: List[Dict]) -> str:
        if self._mimo_client:
            try:
                response = self._mimo_client.chat.completions.create(
                    model=settings.mimo_flash_model,
                    messages=messages,
                    temperature=0.7,
                    max_tokens=800,
                    timeout=30.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"MiMo-Flash批量调用失败，切换Groq: {e}")

        if self._groq_client:
            try:
                response = self._groq_client.chat.completions.create(
                    model=settings.groq_model,
                    messages=messages,
                    temperature=0.7,
                    max_tokens=800,
                    timeout=30.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"Groq批量调用失败，切换DeepSeek: {e}")

        if self._deepseek_client:
            try:
                response = self._deepseek_client.chat.completions.create(
                    model=settings.deepseek_model,
                    messages=messages,
                    temperature=0.7,
                    max_tokens=800,
                    timeout=60.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.error(f"所有批量LLM调用失败: {e}")
                raise Exception(f"所有LLM调用失败: {str(e)}")

        raise Exception("没有可用的LLM客户端")

    def invoke_with_provider(self, messages: List[Dict], provider: str) -> str:
        if provider == self.PROVIDER_FAST and self._groq_client:
            try:
                response = self._groq_client.chat.completions.create(
                    model=settings.groq_model,
                    messages=messages,
                    temperature=0.7,
                    max_tokens=500,
                    timeout=30.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"Groq指定调用失败: {e}")
                return self.invoke(messages)

        elif provider == self.PROVIDER_MIMO_FLASH and self._mimo_client:
            try:
                response = self._mimo_client.chat.completions.create(
                    model=settings.mimo_flash_model,
                    messages=messages,
                    temperature=0.7,
                    max_tokens=500,
                    timeout=30.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"MiMo-Flash指定调用失败: {e}")
                return self.invoke(messages)

        elif provider == self.PROVIDER_MIMO_PRO and self._mimo_client:
            try:
                response = self._mimo_client.chat.completions.create(
                    model=settings.mimo_pro_model,
                    messages=messages,
                    temperature=0.8,
                    max_tokens=2000,
                    timeout=60.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"MiMo-Pro指定调用失败: {e}")
                return self._invoke_high_quality(messages)

        elif provider == self.PROVIDER_DEEPSEEK and self._deepseek_client:
            try:
                response = self._deepseek_client.chat.completions.create(
                    model=settings.deepseek_model,
                    messages=messages,
                    temperature=0.7,
                    max_tokens=500,
                    timeout=60.0
                )
                return response.choices[0].message.content.strip()
            except Exception as e:
                logger.warning(f"DeepSeek指定调用失败: {e}")
                return self.invoke(messages)

        return self.invoke(messages)
