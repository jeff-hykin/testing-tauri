import { defineConfig } from "vite";
import { resolve } from "path";

// https://vitejs.dev/config/
export default defineConfig({
  root: "./",
//   rollupOptions: {
//     input: {
//       main: resolve(__dirname, "index.html"),
//     },
//   },
  resolve: {
    alias: {
      "~": resolve(__dirname, "./"),
      "@src": resolve(__dirname, "src"),
    },
  },
});
