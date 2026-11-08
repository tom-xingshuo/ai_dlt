import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// 体彩接口有 Referer 校验且不允许跨域, 开发/预览时通过代理转发
const lotteryProxy = {
  '/lottery-api': {
    target: 'https://webapi.sporttery.cn',
    changeOrigin: true,
    rewrite: (path: string) => path.replace(/^\/lottery-api/, ''),
    headers: { Referer: 'https://static.sporttery.cn/' },
  },
};

export default defineConfig({
  plugins: [react()],
  server: { port: 5173, proxy: lotteryProxy },
  preview: { port: 4173, proxy: lotteryProxy },
});
