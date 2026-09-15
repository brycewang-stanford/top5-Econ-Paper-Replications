# -*- coding: utf-8 -*-
"""为《机器学习与因果推断》综述解读文档生成中文原创图表。"""
import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch, Rectangle, Circle

plt.rcParams["font.sans-serif"] = ["PingFang SC", "Hiragino Sans GB", "Arial Unicode MS"]
plt.rcParams["axes.unicode_minus"] = False
plt.rcParams["figure.dpi"] = 150
plt.rcParams["savefig.dpi"] = 150
plt.rcParams["savefig.bbox"] = "tight"
plt.rcParams["axes.edgecolor"] = "#9AA4B2"
plt.rcParams["axes.labelcolor"] = "#1F2937"
plt.rcParams["text.color"] = "#1F2937"
plt.rcParams["xtick.color"] = "#4B5563"
plt.rcParams["ytick.color"] = "#4B5563"

OUT = "/Users/brycewang/Documents/GitHub/top5-Econ-Paper-Replications/2025-ML-Causal-Review/images"
os.makedirs(OUT, exist_ok=True)

BLUE = "#2E5EAA"
ORANGE = "#E07A5F"
GREEN = "#3D9970"
GRAY = "#6B7280"
LBLUE = "#DCE7F5"
LORANGE = "#FBE3DA"
LGREEN = "#DDEEE4"
LGRAY = "#EEF0F3"


def save(fig, name):
    p = os.path.join(OUT, name)
    fig.savefig(p, facecolor="white")
    plt.close(fig)
    print("saved", name)


def box(ax, x, y, w, h, text, fc, ec, fs=10, weight="normal", tc="#1F2937"):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.012,rounding_size=0.02",
                                linewidth=1.4, facecolor=fc, edgecolor=ec))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center",
            fontsize=fs, fontweight=weight, color=tc, linespacing=1.5)


def arrow(ax, p1, p2, color=GRAY, lw=1.6, style="-|>", rad=0.0):
    ax.add_patch(FancyArrowPatch(p1, p2, arrowstyle=style, mutation_scale=14,
                                 linewidth=lw, color=color,
                                 connectionstyle=f"arc3,rad={rad}"))


# ---------------------------------------------------------------- 图1 知识地图
def fig1():
    fig, ax = plt.subplots(figsize=(10.5, 6.6))
    ax.set_xlim(0, 10); ax.set_ylim(0, 6.6); ax.axis("off")

    box(ax, 0.2, 5.5, 9.6, 0.85, "图1　机器学习（ML）：擅长“预测”  →  因果机器学习（Causal ML）：把预测能力用于“识别因果”",
        LBLUE, BLUE, fs=12, weight="bold", tc=BLUE)

    # 左：监督学习方法
    box(ax, 0.2, 2.5, 3.0, 2.6, "", "#FFFFFF", GRAY)
    ax.text(1.7, 4.9, "① 工具箱：监督学习", ha="center", fontsize=11.5, fontweight="bold", color=BLUE)
    items = ["Lasso 回归\n（变量筛选、系数压缩）",
             "决策树\n（非线性、交互项）",
             "随机森林\n（多树平均、更稳）",
             "神经网络\n（文本 / 图像等非结构化数据）"]
    for i, t in enumerate(items):
        box(ax, 0.42, 4.30 - i * 0.47, 2.56, 0.40, t, LGRAY, "#C7CDD6", fs=8.2)

    # 中：两大任务
    box(ax, 3.5, 2.5, 3.0, 2.6, "", "#FFFFFF", GRAY)
    ax.text(5.0, 4.9, "② 因果 ML 解决两件事", ha="center", fontsize=11.5, fontweight="bold", color=ORANGE)
    box(ax, 3.72, 3.72, 2.56, 0.95, "A. 控制混杂变量\n在几十上百个控制变量里\n只挑“该控的”，兼顾无偏与精度", LORANGE, ORANGE, fs=8.6)
    box(ax, 3.72, 2.68, 2.56, 0.95, "B. 挖掘异质性效应\n谁受益最多、谁受益最少\n由数据说了算，而非研究者拍脑袋", LORANGE, ORANGE, fs=8.6)

    # 右：代表性估计量
    box(ax, 6.8, 2.5, 3.0, 2.6, "", "#FFFFFF", GRAY)
    ax.text(8.3, 4.9, "③ 两大主力估计量", ha="center", fontsize=11.5, fontweight="bold", color=GREEN)
    box(ax, 7.02, 3.72, 2.56, 0.95, "双重机器学习 Double ML\n（Chernozhukov et al., 2018）\n目标：平均效应更准更稳", LGREEN, GREEN, fs=8.6)
    box(ax, 7.02, 2.68, 2.56, 0.95, "因果森林 Causal Forest\n（Wager & Athey, 2018）\n目标：条件平均效应 CATE", LGREEN, GREEN, fs=8.6)

    for x0, x1 in [(3.2, 3.5), (6.5, 6.8)]:
        arrow(ax, (x0, 3.8), (x1, 3.8), color=GRAY)

    box(ax, 0.2, 0.25, 9.6, 1.95, "", "#FFFFFF", "#C7CDD6")
    ax.text(5.0, 1.98, "④ 必须警惕的四条“红线”", ha="center", fontsize=11.5, fontweight="bold", color="#B4232A")
    warns = ["遗漏变量偏误\nML 不能替你\n观测到“能力”", "对撞偏误\n控制了内生变量\n反而制造出偏误", "黑箱与不稳定\n预测稳，但\n模型结构不稳", "数据与算力\n异质性分析\n需要大样本"]
    for i, t in enumerate(warns):
        box(ax, 0.45 + i * 2.35, 0.45, 2.15, 1.30, t, "#FBE9EA", "#D98A8E", fs=8.6)

    ax.text(9.8, 0.03, "图表来源：作者根据 Strittmatter (2025, IZA WoL 516) 内容整理", ha="right",
            fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig1-causal-ml-map.png")


# ---------------------------------------------------- 图2 偏差-方差权衡
def fig2():
    fig, ax = plt.subplots(figsize=(8.2, 4.8))
    c = np.linspace(0.35, 10, 400)
    bias2 = 9.0 / c ** 1.15
    var = 0.16 * c ** 1.35
    total = bias2 + var + 1.0
    ax.plot(c, bias2, color=BLUE, lw=2.4, label="偏差²（模型太简单 → 抓不住规律）")
    ax.plot(c, var, color=ORANGE, lw=2.4, label="方差（模型太复杂 → 学到了噪声）")
    ax.plot(c, total, color="#111827", lw=2.8, label="总的预测误差 = 偏差² + 方差 + 不可约误差")
    k = int(np.argmin(total))
    ax.axvline(c[k], color=GREEN, ls="--", lw=1.6)
    ax.plot([c[k]], [total[k]], "o", color=GREEN, ms=9, zorder=5)
    ax.annotate("交叉验证要找的“甜点”\n（最优模型复杂度）", xy=(c[k], total[k]), xytext=(c[k] + 1.5, total[k] + 5.2),
                fontsize=10, color=GREEN,
                arrowprops=dict(arrowstyle="->", color=GREEN, lw=1.5))
    ax.text(1.35, 13.5, "欠拟合\n(underfitting)", fontsize=9.5, color=BLUE, ha="center")
    ax.text(8.7, 13.5, "过拟合\n(overfitting)", fontsize=9.5, color=ORANGE, ha="center")
    ax.set_xlabel("模型复杂度（变量个数 / 树的深度 / 网络层数 …）")
    ax.set_ylabel("误差大小")
    ax.set_ylim(0, 22); ax.set_xlim(0.35, 10)
    ax.set_yticks([]); ax.set_xticks([])
    ax.legend(frameon=False, fontsize=9.5, loc="upper center")
    ax.set_title("图2　偏差—方差权衡：机器学习为什么必须做交叉验证", fontsize=12.5, fontweight="bold", pad=12)
    ax.spines[["top", "right"]].set_visible(False)
    fig.text(0.98, -0.02, "示意图，作者绘制", ha="right", fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig2-bias-variance.png")


# ---------------------------------------------------- 图3 K折交叉验证
def fig3():
    fig, ax = plt.subplots(figsize=(8.6, 4.2))
    ax.set_xlim(0, 10.6); ax.set_ylim(0, 5.6); ax.axis("off")
    K = 5
    ax.text(0.1, 5.25, "图3　5 折交叉验证（k-fold cross-validation）", fontsize=12.5, fontweight="bold")
    ax.text(0.1, 4.82, "把样本切成 5 份；每一轮用 4 份“学”，剩下 1 份“考”，轮流坐庄，每个观测都当过考卷但绝不同时既学又考。",
            fontsize=9.2, color=GRAY)
    for r in range(K):
        y = 3.80 - r * 0.70
        ax.text(0.05, y + 0.16, f"第 {r+1} 轮", fontsize=9.5, va="center")
        for j in range(K):
            x = 1.35 + j * 1.78
            test = (j == r)
            ax.add_patch(Rectangle((x, y - 0.06), 1.68, 0.46,
                                   facecolor=ORANGE if test else LBLUE,
                                   edgecolor=BLUE if not test else "#B4532F", lw=1.2))
            ax.text(x + 0.84, y + 0.17, "测试" if test else "训练", ha="center", va="center",
                    fontsize=9, color="white" if test else BLUE, fontweight="bold" if test else "normal")
    for j in range(K):
        ax.text(1.35 + j * 1.78 + 0.84, 4.36, f"折 {j+1}", ha="center", fontsize=9, color=GRAY)
    ax.text(0.05, 0.18, "→ 5 轮的测试误差取平均，用来挑选模型的“复杂度旋钮”（如 Lasso 的惩罚参数 λ）。",
            fontsize=9.6, color=BLUE)
    fig.text(0.98, 0.0, "示意图，作者绘制", ha="right", fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig3-kfold-cv.png")


# ---------------------------------------------------- 图4 Lasso 收缩
def fig4():
    rng = np.random.default_rng(7)
    p, n = 8, 400
    X = rng.normal(size=(n, p))
    X = X / np.linalg.norm(X, axis=0) * np.sqrt(n)      # 近似正交标准化
    beta = np.array([1.8, -1.3, 0.9, 0.55, 0.25, 0.0, 0.0, 0.0])
    y = X @ beta + rng.normal(scale=1.6, size=n)
    ols = np.linalg.lstsq(X, y, rcond=None)[0]
    lam = np.linspace(0, 1.9, 200)
    paths = np.sign(ols)[None, :] * np.maximum(np.abs(ols)[None, :] - lam[:, None], 0)

    fig, ax = plt.subplots(figsize=(8.2, 4.6))
    names = [f"变量{i+1}" for i in range(p)]
    cols = [BLUE, ORANGE, GREEN, "#8E6FB6", "#C9A227", "#9AA4B2", "#9AA4B2", "#9AA4B2"]
    for j in range(p):
        ax.plot(lam, paths[:, j], color=cols[j], lw=2.0 if j < 5 else 1.2,
                ls="-" if j < 5 else "--",
                label=names[j] + ("（真实系数≠0）" if beta[j] != 0 else "（真实系数=0）"))
    ax.axhline(0, color="#111827", lw=0.8)
    ax.set_xlabel("惩罚力度 λ（越往右，惩罚越强）")
    ax.set_ylabel("Lasso 估计系数")
    ax.set_title("图4　Lasso 如何“边估计边选变量”：系数被压缩，弱变量直接归零", fontsize=12, fontweight="bold", pad=12)
    ax.legend(frameon=False, fontsize=8, ncol=2, loc="upper right")
    ax.spines[["top", "right"]].set_visible(False)
    ax.annotate("λ 太大 → 有用的变量也被误杀（偏差↑）", xy=(1.55, 0.05), xytext=(0.85, -1.15),
                fontsize=9, color="#B4232A", arrowprops=dict(arrowstyle="->", color="#B4232A"))
    fig.text(0.98, -0.02, "模拟数据示意（n=400, p=8），作者绘制", ha="right", fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig4-lasso-shrinkage.png")


# ---------------------------------------------------- 图5 决策树 vs 因果树
def fig5():
    fig, axes = plt.subplots(1, 2, figsize=(10.4, 4.6))
    for ax in axes:
        ax.set_xlim(0, 10); ax.set_ylim(0, 6.4); ax.axis("off")

    ax = axes[0]
    ax.text(5, 6.0, "决策树 / 随机森林：目标是「预测得准」", ha="center", fontsize=11.5, fontweight="bold", color=BLUE)
    box(ax, 3.4, 4.7, 3.2, 0.85, "全样本\n分裂准则：让 Y 的预测误差最小", LBLUE, BLUE, fs=8.8)
    box(ax, 0.7, 2.9, 3.6, 0.85, "受教育年限 < 12", "#FFFFFF", BLUE, fs=9)
    box(ax, 5.7, 2.9, 3.6, 0.85, "受教育年限 ≥ 12", "#FFFFFF", BLUE, fs=9)
    box(ax, 0.7, 1.1, 3.6, 0.95, "叶子：预测工资\nŶ = 3.1 万", LGRAY, "#C7CDD6", fs=9)
    box(ax, 5.7, 1.1, 3.6, 0.95, "叶子：预测工资\nŶ = 5.8 万", LGRAY, "#C7CDD6", fs=9)
    arrow(ax, (4.4, 4.7), (2.5, 3.75)); arrow(ax, (5.6, 4.7), (7.5, 3.75))
    arrow(ax, (2.5, 2.9), (2.5, 2.05)); arrow(ax, (7.5, 2.9), (7.5, 2.05))
    ax.text(5, 0.35, "输出：一个数值预测", ha="center", fontsize=9.5, color=GRAY)

    ax = axes[1]
    ax.text(5, 6.0, "因果树 / 因果森林：目标是「效应差得开」", ha="center", fontsize=11.5, fontweight="bold", color=ORANGE)
    box(ax, 3.4, 4.7, 3.2, 0.85, "全样本\n分裂准则：让两组的处理效应差最大", LORANGE, ORANGE, fs=8.8)
    box(ax, 0.7, 2.9, 3.6, 0.85, "年龄 < 35 且 无子女", "#FFFFFF", ORANGE, fs=9)
    box(ax, 5.7, 2.9, 3.6, 0.85, "年龄 ≥ 35 或 有子女", "#FFFFFF", ORANGE, fs=9)
    box(ax, 0.7, 1.1, 3.6, 0.95, "叶子：处理效应\nτ̂ = +8.4 个百分点", LORANGE, ORANGE, fs=9)
    box(ax, 5.7, 1.1, 3.6, 0.95, "叶子：处理效应\nτ̂ = −1.2 个百分点", LORANGE, ORANGE, fs=9)
    arrow(ax, (4.4, 4.7), (2.5, 3.75), color=ORANGE); arrow(ax, (5.6, 4.7), (7.5, 3.75), color=ORANGE)
    arrow(ax, (2.5, 2.9), (2.5, 2.05), color=ORANGE); arrow(ax, (7.5, 2.9), (7.5, 2.05), color=ORANGE)
    ax.text(5, 0.35, "输出：谁受益多、谁受益少", ha="center", fontsize=9.5, color=ORANGE)

    fig.suptitle("图5　同一套“切数据”的算法，换一个目标函数就从预测工具变成因果工具",
                 fontsize=12.5, fontweight="bold", y=1.02)
    fig.text(0.98, -0.01, "示意图（叶子中的数值为虚构示例），作者绘制", ha="right", fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig5-tree-vs-causal-tree.png")


# ---------------------------------------------------- 图6 Double ML 流程
def fig6():
    fig, ax = plt.subplots(figsize=(10.6, 5.2))
    ax.set_xlim(0, 10.6); ax.set_ylim(0, 5.2); ax.axis("off")
    ax.text(0.1, 4.95, "图6　双重机器学习（Double ML）的四步流水线", fontsize=13, fontweight="bold")

    box(ax, 0.15, 2.42, 2.3, 1.62, "第 ① 步\n预测「处理」\nD̂ = ML(X)\n\n例：用全部控制变量\n预测受教育年限", LBLUE, BLUE, fs=9)
    box(ax, 2.65, 2.42, 2.3, 1.62, "第 ② 步\n预测「结果」\nŶ = ML(X)\n\n例：用全部控制变量\n预测工资", LBLUE, BLUE, fs=9)
    box(ax, 5.15, 2.42, 2.3, 1.62, "第 ③ 步\n取残差\n处理残差 = D − 预测D\n结果残差 = Y − 预测Y\n把 X 能解释的部分洗掉", LORANGE, ORANGE, fs=8.2)
    box(ax, 7.65, 2.42, 2.75, 1.62, "第 ④ 步\n残差对残差回归\nỸ = θ·D̃ + ε\n\nθ̂ 就是因果效应\n（一致、渐近正态）", LGREEN, GREEN, fs=9)
    for x in (2.45, 4.95, 7.45):
        arrow(ax, (x, 3.23), (x + 0.2, 3.23))

    box(ax, 0.15, 0.95, 10.25, 1.25, "", "#FFFFFF", "#C7CDD6")
    ax.text(0.4, 1.92, "贯穿全程的关键护栏：交叉拟合（cross-fitting）", fontsize=10.5, fontweight="bold", color=BLUE)
    ax.text(0.4, 1.30, "把样本分成 K 折：第 ①②步的 ML 模型只在「其他 K−1 折」上训练，残差只在「留出的那一折」上计算。\n"
                       "这样 ML 的过拟合就不会“渗透”到 θ̂ 里 —— 这是 Double ML 能给出可靠标准误的根本原因。",
            fontsize=9.3, color="#374151", linespacing=1.6)
    ax.text(10.45, 0.35, "整理自 Chernozhukov et al. (2018) 与 Strittmatter (2025)", ha="right",
            fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig6-doubleml-pipeline.png")


# ---------------------------------------------------- 图7 残差化直觉
def fig7():
    rng = np.random.default_rng(3)
    n = 500
    X = rng.normal(size=n)                       # 混杂变量（如“能力”被观测到的代理）
    D = 1.2 * X + 0.4 * X ** 2 + rng.normal(scale=1.0, size=n)   # 处理
    tau = 1.0
    Y = tau * D + 2.5 * X + 0.9 * X ** 2 + rng.normal(scale=1.0, size=n)

    def resid(v):
        c = np.polyfit(X, v, 3)
        return v - np.polyval(c, X)

    Dt, Yt = resid(D), resid(Y)
    b_raw = np.polyfit(D, Y, 1)[0]
    b_dml = np.polyfit(Dt, Yt, 1)[0]

    fig, axes = plt.subplots(1, 2, figsize=(10.2, 4.4))
    ax = axes[0]
    ax.scatter(D, Y, s=9, color=BLUE, alpha=0.35, edgecolors="none")
    xs = np.linspace(D.min(), D.max(), 50)
    ax.plot(xs, np.polyval(np.polyfit(D, Y, 1), xs), color="#B4232A", lw=2.4)
    ax.set_title(f"① 直接回归 Y 对 D\n斜率 = {b_raw:.2f}（真值 1.00，被混杂拉高）", fontsize=10.5, color="#B4232A")
    ax.set_xlabel("处理变量 D"); ax.set_ylabel("结果变量 Y")

    ax = axes[1]
    ax.scatter(Dt, Yt, s=9, color=GREEN, alpha=0.35, edgecolors="none")
    xs = np.linspace(Dt.min(), Dt.max(), 50)
    ax.plot(xs, np.polyval(np.polyfit(Dt, Yt, 1), xs), color=GREEN, lw=2.4)
    ax.set_title(f"② Double ML：残差 Ỹ 对残差 D̃\n斜率 = {b_dml:.2f}（≈ 真值 1.00）", fontsize=10.5, color=GREEN)
    ax.set_xlabel("处理残差 D̃"); ax.set_ylabel("结果残差 Ỹ")

    for ax in axes:
        ax.spines[["top", "right"]].set_visible(False)
    fig.suptitle("图7　“残差化”到底做了什么：把控制变量能解释的部分先洗掉，剩下的关系才是因果",
                 fontsize=12, fontweight="bold", y=1.04)
    fig.text(0.98, -0.03, "模拟数据（n=500，真实效应=1.0），作者绘制", ha="right", fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig7-residualization.png")


# ---------------------------------------------------- 图8 定居者死亡率森林图
def fig8():
    labels = ["① 原始 IV（AJR 2001）\n少量控制变量",
              "② 加入全部 16 个\n潜在工具变量混杂因子",
              "③ Double ML + Lasso\n只保留相关混杂因子"]
    est = [0.94, 0.90, 0.92]
    se = [0.28, 0.62, 0.31]
    colors = [BLUE, "#B4232A", GREEN]

    fig, ax = plt.subplots(figsize=(8.6, 3.4))
    for i, (e, s, c) in enumerate(zip(est, se, colors)):
        y = 2 - i
        ax.errorbar(e, y, xerr=1.96 * s, fmt="o", color=c, ms=9, capsize=5, lw=2.2)
        sig = "显著" if e - 1.96 * s > 0 else "不显著"
        ax.text(e + 1.96 * s + 0.08, y, f"95% CI 宽度 = {2*1.96*s:.2f}　({sig})", va="center", fontsize=9, color=c)
    ax.axvline(0, color="#111827", lw=1.0, ls="--")
    ax.set_yticks([2, 1, 0]); ax.set_yticklabels(labels, fontsize=9.5)
    ax.set_xlim(-1.0, 3.0); ax.set_ylim(-0.55, 2.55)
    ax.set_xlabel("制度质量对人均 GDP（对数）的估计效应")
    ax.set_title("图8　“定居者死亡率”案例：控制变量一多，传统 IV 就失去精度；Double ML 把精度找了回来",
                 fontsize=11.5, fontweight="bold", pad=12)
    ax.spines[["top", "right", "left"]].set_visible(False)
    fig.text(0.98, -0.13, "示意图：数值为说明性构造，用于展示论文所述“结论一致、置信区间更窄”的模式；"
                          "案例出处 Acemoglu et al. (2001)、Belloni et al. (2014)",
             ha="right", fontsize=7.2, color=GRAY, style="italic")
    save(fig, "fig8-settler-mortality.png")


# ---------------------------------------------------- 图9 异质性分布
def fig9():
    rng = np.random.default_rng(11)
    cate = np.concatenate([rng.normal(-1.5, 2.2, 3000), rng.normal(6.5, 3.2, 4000), rng.normal(14, 3.0, 2000)])
    fig, ax = plt.subplots(figsize=(8.8, 4.4))
    ax.hist(cate, bins=60, color=LBLUE, edgecolor=BLUE, lw=0.5, density=True, label="因果森林估计的个体效应 τ̂(x) 分布")
    ax.axvline(cate.mean(), color="#111827", lw=2.2, ls="-", label=f"平均处理效应 ATE = {cate.mean():.1f}")
    ax.set_xlim(-11, 34)
    top = ax.get_ylim()[1]
    trad = [1.0, 6.0, 9.5]
    tl = ["传统分组①　低学历：+1.0", "传统分组②　中学历：+6.0", "传统分组③　高学历：+9.5"]
    for i, (v, t) in enumerate(zip(trad, tl)):
        ax.axvline(v, color=ORANGE, lw=1.6, ls="--", ymax=0.72 - i * 0.06)
        ax.annotate(t, xy=(v, top * (0.72 - i * 0.06)), xytext=(22, top * (0.72 - i * 0.06)),
                    fontsize=8.5, color=ORANGE, va="center", ha="left",
                    arrowprops=dict(arrowstyle="-", color=ORANGE, lw=0.9, ls=":"))
    ax.text(22, top * 0.80, "传统做法：只能报出 3 个分组均值", fontsize=8.8, color=ORANGE, fontweight="bold")
    ax.set_xlabel("处理效应（如：就业概率提升，个百分点）")
    ax.set_ylabel("密度")
    ax.set_title("图9　只看平均值会错过什么：一个正的 ATE 背后，可能有相当一部分人被“伤害”",
                 fontsize=12, fontweight="bold", pad=12)
    ax.axvspan(cate.min(), 0, color="#FBE9EA", alpha=0.75, zorder=0)
    ax.text(-10.2, top * 0.42, f"效应为负的人群\n约占 {100*np.mean(cate<0):.0f}%", fontsize=9.5, color="#B4232A")
    ax.legend(frameon=False, fontsize=8.8, loc="upper right", bbox_to_anchor=(1.0, 1.0))
    ax.spines[["top", "right"]].set_visible(False)
    fig.text(0.98, -0.03, "模拟数据示意，作者绘制", ha="right", fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig9-cate-distribution.png")


# ---------------------------------------------------- 图10 定向分配
def fig10():
    rng = np.random.default_rng(5)
    n = 5000
    poverty = rng.uniform(0, 1, n)                        # 越大越穷
    # 真实受益程度：与贫困只有弱相关，且高度右偏——少数人能被大幅改变
    benefit = rng.exponential(1.0, n) + 0.35 * poverty
    benefit = benefit / benefit.max()

    def gain(order):
        b = benefit[order]
        return np.cumsum(b) / benefit.sum()

    frac = np.arange(1, n + 1) / n
    g_cate = gain(np.argsort(-benefit))
    g_pov = gain(np.argsort(-poverty))
    g_rand = gain(rng.permutation(n))

    fig, ax = plt.subplots(figsize=(8.2, 4.6))
    ax.plot(frac * 100, g_cate * 100, color=GREEN, lw=2.6, label="① 按“预计受益最多”排序发放（因果森林）")
    ax.plot(frac * 100, g_pov * 100, color=ORANGE, lw=2.4, label="② 按“最贫困”排序发放（传统做法）")
    ax.plot(frac * 100, g_rand * 100, color=GRAY, lw=2.0, ls="--", label="③ 随机发放（基准线）")
    i = int(0.3 * n) - 1
    ax.annotate("", xy=(30, g_cate[i] * 100), xytext=(30, g_pov[i] * 100),
                arrowprops=dict(arrowstyle="<->", color="#B4232A", lw=1.8))
    ax.text(34, (g_cate[i] + g_pov[i]) * 50, f"同样只覆盖 30% 的人，\n总收益相差 {100*(g_cate[i]-g_pov[i]):.0f} 个百分点",
            fontsize=9.6, color="#B4232A", va="center", fontweight="bold")
    ax.set_xlabel("覆盖人群比例（%）"); ax.set_ylabel("累计获得的总效果（占全覆盖的 %）")
    ax.set_title("图10　钱该给“最穷的人”还是“最能被改变的人”？——肯尼亚现金转移案例的核心问题",
                 fontsize=11.5, fontweight="bold", pad=12)
    ax.legend(frameon=False, fontsize=9.2, loc="lower right")
    ax.spines[["top", "right"]].set_visible(False)
    ax.grid(alpha=0.25, ls=":")
    fig.text(0.98, -0.03, "模拟数据示意；问题设定源自 Haushofer et al. (2022)", ha="right",
             fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig10-targeting.png")


# ---------------------------------------------------- 图11 Lasso 不稳定性
def fig11():
    rng = np.random.default_rng(19)
    varnames = ["房间数", "建筑面积", "卧室数", "楼层", "房龄", "学区评分",
                "距地铁", "有车位", "装修等级", "朝向", "小区绿化", "物业费"]
    K, P = 10, len(varnames)
    sel = np.zeros((K, P), dtype=int)
    stable = [3, 5, 6]                      # 稳定入选
    swap_pairs = [(0, 1), (2, 8), (9, 10)]  # 高度相关、互相替代
    for k in range(K):
        sel[k, stable] = 1
        for a, b in swap_pairs:
            sel[k, a if rng.random() < 0.5 else b] = 1
        for j in [4, 7, 11]:
            sel[k, j] = int(rng.random() < 0.35)

    fig, axes = plt.subplots(1, 2, figsize=(11.2, 4.4), gridspec_kw={"width_ratios": [1.55, 1]})
    ax = axes[0]
    ax.imshow(sel, cmap=matplotlib.colors.ListedColormap(["#F3F4F6", BLUE]), aspect="auto")
    ax.set_xticks(range(P)); ax.set_xticklabels(varnames, rotation=55, ha="right", fontsize=8.5)
    ax.set_yticks(range(K)); ax.set_yticklabels([f"子样本 {i+1}" for i in range(K)], fontsize=8.5)
    ax.set_title("① 同一份数据随机切成 10 份，Lasso 选出的变量却各不相同", fontsize=10.5, color=BLUE)
    for i in range(K + 1):
        ax.axhline(i - 0.5, color="white", lw=1.2)
    for j in range(P + 1):
        ax.axvline(j - 0.5, color="white", lw=1.2)
    ax.text(-0.5, K + 1.4, "深色 = 被选入模型　浅色 = 系数被压缩为 0", fontsize=8.5, color=GRAY)

    ax = axes[1]
    base = rng.normal(300, 80, 400)
    p1 = base + rng.normal(0, 12, 400)
    p2 = base + rng.normal(0, 12, 400)
    ax.scatter(p1, p2, s=10, color=GREEN, alpha=0.45, edgecolors="none")
    lim = [80, 520]
    ax.plot(lim, lim, color="#111827", lw=1.2, ls="--")
    r = np.corrcoef(p1, p2)[0, 1]
    ax.set_xlim(lim); ax.set_ylim(lim)
    ax.set_xlabel("子样本 1 模型的预测房价（万元）")
    ax.set_ylabel("子样本 2 模型的预测房价（万元）")
    ax.set_title(f"② 但预测值高度一致（相关系数 ≈ {r:.2f}）", fontsize=10.5, color=GREEN)
    ax.spines[["top", "right"]].set_visible(False)

    fig.suptitle("图11　“模型不稳、预测很稳”：为什么不能把 Lasso 选中的变量当作因果解释",
                 fontsize=12.5, fontweight="bold", y=1.05)
    fig.text(0.98, -0.06, "模拟数据示意；案例源自 Mullainathan & Spiess (2017)", ha="right",
             fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig11-lasso-instability.png")


# ---------------------------------------------------- 图12 DAG：混杂 vs 对撞
def fig12():
    fig, axes = plt.subplots(1, 2, figsize=(11.0, 4.8))
    for ax in axes:
        ax.set_xlim(0, 10); ax.set_ylim(0, 7.6); ax.axis("off")

    def node(ax, x, y, t, fc, ec, r=0.75):
        ax.add_patch(Circle((x, y), r, facecolor=fc, edgecolor=ec, lw=1.8))
        ax.text(x, y, t, ha="center", va="center", fontsize=9.5, fontweight="bold", color="#1F2937")

    ax = axes[0]
    ax.text(5, 7.1, "混杂变量 X：必须控制", ha="center", fontsize=12, fontweight="bold", color=GREEN)
    node(ax, 5, 5.4, "能力 X", LGREEN, GREEN)
    node(ax, 2.2, 2.9, "教育 D", LBLUE, BLUE)
    node(ax, 7.8, 2.9, "工资 Y", LBLUE, BLUE)
    arrow(ax, (4.45, 4.95), (2.75, 3.45), color=GREEN, lw=2)
    arrow(ax, (5.55, 4.95), (7.25, 3.45), color=GREEN, lw=2)
    arrow(ax, (2.98, 2.9), (7.02, 2.9), color=BLUE, lw=2)
    ax.text(5, 1.0, "X 同时影响 D 和 Y → 不控制就有遗漏变量偏误\nDouble ML 的强项：在几百个候选里自动挑出该控的 X",
            ha="center", fontsize=9.2, color=GREEN, linespacing=1.8)

    ax = axes[1]
    ax.text(5, 7.1, "对撞变量 C：绝不能控制", ha="center", fontsize=12, fontweight="bold", color="#B4232A")
    node(ax, 5, 3.0, "当期收入 C", "#FBE9EA", "#B4232A", r=0.88)
    node(ax, 2.2, 5.6, "培训 D", LBLUE, BLUE)
    node(ax, 7.8, 5.6, "就业 Y", LBLUE, BLUE)
    arrow(ax, (2.66, 5.05), (4.35, 3.55), color="#B4232A", lw=2)
    arrow(ax, (7.34, 5.05), (5.65, 3.55), color="#B4232A", lw=2)
    arrow(ax, (2.98, 5.6), (7.02, 5.6), color=BLUE, lw=2)
    ax.text(5, 1.0, "D 和 Y 共同影响 C → 一旦控制 C，就在 D 与 Y 之间凭空造出一条假通路\nDouble ML 尤其危险：C 预测力强，会被 ML 优先选中，把偏误放大",
            ha="center", fontsize=9.2, color="#B4232A", linespacing=1.8)

    fig.suptitle("图12　同样是“控制变量”，一个救命一个要命", fontsize=13, fontweight="bold", y=1.03)
    fig.text(0.98, -0.02, "作者绘制", ha="right", fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig12-confounder-vs-collider.png")


# ---------------------------------------------------- 图13 性别工资差距
def fig13():
    fig, ax = plt.subplots(figsize=(8.4, 4.3))
    labels = ["50 个控制变量\n（不含婚姻状态）", "50 个控制变量\n+ 婚姻状态"]
    vals = [100, 110]
    bars = ax.bar(labels, vals, width=0.5, color=[BLUE, "#B4232A"], edgecolor="none")
    for b, v in zip(bars, vals):
        ax.text(b.get_x() + b.get_width() / 2, v + 1.5, f"{v}", ha="center", fontsize=12, fontweight="bold",
                color=b.get_facecolor())
    ax.annotate("", xy=(1, 110), xytext=(1, 100), arrowprops=dict(arrowstyle="<->", color="#B4232A", lw=2))
    ax.text(1.32, 105, "多出 10%\n仅仅因为多放进了\n一个内生变量（婚姻状态）", fontsize=10, color="#B4232A", va="center")
    ax.set_ylim(0, 132); ax.set_xlim(-0.55, 2.55)
    ax.set_ylabel("估计出的性别工资差距（以左侧为 100）")
    ax.set_title("图13　PSID 案例：Double ML 对单个内生变量有多敏感", fontsize=12, fontweight="bold", pad=12)
    ax.spines[["top", "right"]].set_visible(False)
    ax.grid(axis="y", alpha=0.25, ls=":")
    fig.text(0.98, -0.03, "数值依据 Hünermund et al. (2023)，经指数化处理；作者绘制", ha="right",
             fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig13-gender-gap.png")


# ---------------------------------------------------- 图14 样本量与功效
def fig14():
    from math import erf, sqrt
    def Phi(z):
        return 0.5 * (1 + erf(z / sqrt(2)))
    n = np.arange(200, 20001, 100)
    fig, ax = plt.subplots(figsize=(8.2, 4.4))
    for d, c, lab in [(0.30, GREEN, "异质性很强（效应差 = 0.30 个标准差）"),
                      (0.15, BLUE, "异质性中等（0.15 个标准差）"),
                      (0.07, ORANGE, "异质性温和（0.07 个标准差）")]:
        se = 2.0 / np.sqrt(n)
        power = np.array([1 - Phi(1.96 - d / s) + Phi(-1.96 - d / s) for s in se])
        ax.plot(n, power * 100, color=c, lw=2.4, label=lab)
    ax.axhline(80, color="#111827", ls="--", lw=1.2)
    ax.text(200, 82, "常用的 80% 功效门槛", fontsize=9, color="#111827")
    ax.set_xlabel("样本量 n")
    ax.set_ylabel("检出异质性的统计功效（%）")
    ax.set_xscale("log")
    ax.set_ylim(0, 105)
    ax.set_title("图14　为什么因果森林“吃”样本：异质性越温和，需要的样本量越是成倍上升",
                 fontsize=11.5, fontweight="bold", pad=12)
    ax.legend(frameon=False, fontsize=9.2, loc="lower right")
    ax.grid(alpha=0.25, ls=":")
    ax.spines[["top", "right"]].set_visible(False)
    fig.text(0.98, -0.03, "按两样本均值差检验的功效公式计算的示意图，作者绘制", ha="right",
             fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig14-power-sample-size.png")


# ---------------------------------------------------- 图15 方法选择决策图
def fig15():
    fig, ax = plt.subplots(figsize=(10.4, 5.8))
    ax.set_xlim(0, 10.4); ax.set_ylim(0, 5.8); ax.axis("off")
    ax.text(0.1, 5.55, "图15　我该用哪种方法？一张决策图", fontsize=13, fontweight="bold")

    box(ax, 3.6, 4.45, 3.2, 0.72, "你的研究问题是什么？", LBLUE, BLUE, fs=10.5, weight="bold")
    box(ax, 0.15, 2.95, 3.0, 0.8, "只想要一个\n可靠的平均效应", "#FFFFFF", GRAY, fs=9.5)
    box(ax, 3.6, 2.95, 3.2, 0.8, "想知道\n“谁受益、谁受损”", "#FFFFFF", GRAY, fs=9.5)
    box(ax, 7.25, 2.95, 3.0, 0.8, "只想预测\n（不涉及因果）", "#FFFFFF", GRAY, fs=9.5)
    arrow(ax, (4.6, 4.45), (1.65, 3.75), rad=0.15)
    arrow(ax, (5.2, 4.45), (5.2, 3.75))
    arrow(ax, (5.8, 4.45), (8.75, 3.75), rad=-0.15)

    box(ax, 0.15, 1.35, 3.0, 1.25, "Double ML\n（partialling-out / PLR）\n\n控制变量多、关系非线性时\n比逐个手挑更稳更准", LGREEN, GREEN, fs=9)
    box(ax, 3.6, 1.35, 3.2, 1.25, "因果森林 / 广义随机森林\n（Causal Forest, GRF）\n\n输出 CATE、变量重要性、\n最优分配策略（policy tree）", LORANGE, ORANGE, fs=9)
    box(ax, 7.25, 1.35, 3.0, 1.25, "普通监督学习\n（Lasso / RF / 神经网络）\n\n别把选出的变量\n当成因果解释", LGRAY, "#C7CDD6", fs=9)
    for x in (1.65, 5.2, 8.75):
        arrow(ax, (x, 2.95), (x, 2.6))

    box(ax, 0.15, 0.15, 10.1, 1.0, "", "#FBE9EA", "#D98A8E")
    ax.text(5.2, 0.65, "三条路都绕不开的前提：识别策略要站得住脚——该观测的混杂变量必须真的观测到，\n"
                       "并且要坚决把「在结果之后才发生的变量」挡在模型之外。",
            ha="center", va="center", fontsize=9.6, color="#B4232A", linespacing=1.8)
    fig.text(0.98, -0.01, "作者绘制", ha="right", fontsize=7.5, color=GRAY, style="italic")
    save(fig, "fig15-method-choice.png")


for f in [fig1, fig2, fig3, fig4, fig5, fig6, fig7, fig8, fig9, fig10, fig11, fig12, fig13, fig14, fig15]:
    f()
print("ALL DONE")
