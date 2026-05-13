# 🍱 Pixel-art Cafeteria Simulation System
### 基于 Godot 引擎的星露谷风格食堂仿真系统

这是一个采用 **星露谷物语 (Stardew Valley)** 风格像素美术开发的模拟系统。项目旨在通过离散事件仿真逻辑，模拟食堂在高峰时段的就餐场景、窗口排队调度以及学生与环境的交互。

---

## 🌟 核心特性

*   **仿真引擎**: 基于 Godot 4.x 开发，通过自定义脚本实现复杂的排队与服务逻辑。
*   **像素美术**: 采用 2D 像素风格，致力于还原温馨的经营类游戏视觉体验。
*   **排队算法**: 实现了窗口人数动态监控，支持“正常营业”、“极度拥挤”等状态的实时判定。
*   **状态机交互**: 学生个体具有独立状态机（ActivityState），涵盖排队中（ORDERING）、就餐准备（ORDER_COMPLETED）等状态。
*   **智能信息交互**: 悬停查看窗口状态、今日菜谱及实时排队人数。

## 🛠️ 技术栈

- **Game Engine:** Godot 4 (GDScript)
- **Art Style:** Pixel Art (Stardew-like)
- **Architecture:** 
  - `SimulationEngine` (Autoload 单例控制中心)
  - `Window.gd` (窗口交互逻辑)
  - `InfoBox` (动态 UI 信息展示)

## 🚀 快速开始

1. 确保已安装 **Godot 4.x**。
2. 克隆本仓库：
   ```bash
   git clone git@github.com:Miracle-clo/Pixel-art-Programming.git
