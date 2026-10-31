"""JOB-024 stage 1. Run from any cwd; assets resolve beside this file."""
from pathlib import Path
from manim import *

BG = "#FBF6EC"
BLUE = "#3F6FB5"
ORANGE = "#F08A6A"
GREEN = "#8DAA7F"
INK = "#233554"
FONT = "Noto Sans CJK TC"
ASSETS = Path(__file__).resolve().parent / "images"


class AnnuityPV(Scene):
    def construct(self):
        self.camera.background_color = BG

        def txt(s, size=32, color=INK):
            return Text(s, font=FONT, font_size=size, color=color)

        def math(s, size=40, color=INK):
            return MathTex(s, font_size=size, color=color)

        def until(t):
            # Static waits use int(duration / dt). A tiny subframe guard avoids
            # losing a frame through floating-point truncation in Manim 0.22.
            frames = round((t - self.time) * config.frame_rate)
            if frames > 0:
                self.wait((frames + 0.001) / config.frame_rate)
            assert abs(self.time - t) < 0.02, (self.time, t)

        def clear():
            self.play(*[FadeOut(m) for m in list(self.mobjects)], run_time=1)

        # 00:00–00:15: establish the rent example.
        title = txt("普通年金的現值", 44).move_to([0, 3.35, 0])
        rent = ImageMobject(str(ASSETS / "02_rent.jpg")).set_height(5.4).move_to([0, 0.15, 0])
        self.play(FadeIn(rent), FadeIn(title), run_time=2)
        self.play(rent.animate.scale(1.08), run_time=13, rate_func=linear)

        # 00:15–00:30: end-of-month payments define an ordinary annuity.
        self.play(rent.animate.set_width(5.4).move_to([3.8, 0.45, 0]), run_time=2)
        question = VGroup(txt("一次付清，", 37), txt("要付多少才公平？", 37))
        question.arrange(DOWN, aligned_edge=LEFT, buff=0.24).move_to([-3.1, 1.15, 0])
        terms = VGroup(txt("每月底付 1,000 元", 27, BLUE),
                       txt("共 36 期 · 月利率 1%", 27, BLUE))
        terms.arrange(DOWN, aligned_edge=LEFT, buff=0.22).next_to(question, DOWN, buff=0.6, aligned_edge=LEFT)
        self.play(FadeIn(question, shift=UP * 0.2), FadeIn(terms), run_time=2)
        until(29)
        clear()

        # 00:30–00:50: three payment arrows share their x coordinate with values.
        heading = txt("先看 3 期：把未來的錢折回現在", 34).move_to([0, 3.15, 0])
        xs = [-5.5, -1.9, 1.7, 5.3]
        axis = Arrow([-5.9, 1.3, 0], [6.15, 1.3, 0], buff=0, color=BLUE)
        ticks = VGroup(*[VGroup(Line([x, 1.16, 0], [x, 1.44, 0], color=BLUE),
                                txt(str(k), 27).move_to([x, 1.8, 0])) for k, x in enumerate(xs)])
        self.play(FadeIn(heading), Create(axis), FadeIn(ticks), run_time=2)
        arrows = VGroup(*[Arrow([x, 1.12, 0], [x, 0.2, 0], buff=0, color=BLUE) for x in xs[1:]])
        payments = VGroup(*[txt("1,000", 28).move_to([x, -0.12, 0]) for x in xs[1:]])
        self.play(LaggedStart(*[AnimationGroup(GrowArrow(a), FadeIn(p)) for a, p in zip(arrows, payments)], lag_ratio=0.3), run_time=3)
        origin = txt("現在", 25, BLUE).move_to([xs[0] - 0.85, 0.65, 0])
        self.play(FadeIn(origin), run_time=1)
        for x, value in zip(xs[1:], ["990.10", "980.30", "970.59"]):
            # Keep the return path in the gap between payments and PV labels.
            # The vertical tip reaches the actual period-0 tick.
            path = VGroup(
                Line([x, -0.48, 0], [xs[0], -0.48, 0], color=ORANGE, stroke_width=3),
                Arrow([xs[0], -0.48, 0], [xs[0], 1.1, 0], buff=0,
                      color=ORANGE, stroke_width=3, tip_length=0.18),
            )
            present = txt(value, 30, ORANGE).move_to([x, -0.95, 0])
            self.play(Create(path), FadeIn(present, shift=UP * 0.2), run_time=1.4)
            self.play(FadeOut(path), run_time=0.6)
        total = VGroup(txt("3 期現值合計", 27), txt("2,940.99", 36, ORANGE)).arrange(RIGHT, buff=0.4).move_to([0, -2.05, 0])
        self.play(FadeIn(total), run_time=1)
        until(49)
        clear()

        # 00:50–01:05: all Chinese uses Text; MathTex contains mathematics only.
        heading = txt("每一期現值相加，就是年金現值", 34).move_to([0, 3.15, 0])
        series = math(r"PV = A v + A v^2 + \cdots + A v^n", 47).move_to([0, 1.0, 0])
        factor = VGroup(txt("折現因子", 29, BLUE), math(r"v = \frac{1}{1+i}", 40, BLUE)).arrange(RIGHT, buff=0.5).move_to([0, -0.8, 0])
        self.play(FadeIn(heading), Write(series), run_time=3)
        self.play(FadeIn(factor), run_time=2)
        until(64)
        clear()

        # 01:05–01:25: term columns align, and green boxes identify cancellation.
        heading = txt("乘上 (1+i)，再把兩式相減", 34).move_to([0, 3.15, 0])
        row1 = MathTex(r"(1+i)PV", "=", "A", "+", r"A v + \cdots + A v^{n-1}", font_size=35, color=INK)
        row2 = MathTex("PV", "=", r"A v + \cdots + A v^{n-1}", "+", r"A v^n", font_size=35, color=INK)
        # Explicit positions keep the equal signs aligned and leave room at edges.
        row1.move_to([0, 1.95, 0]); row2.move_to([0, 0.7, 0])
        row2.shift((row1[1].get_x() - row2[1].get_x()) * RIGHT)
        self.play(FadeIn(heading), Write(row1), Write(row2), run_time=3)
        boxes = VGroup(SurroundingRectangle(row1[4], color=GREEN, buff=0.12),
                       SurroundingRectangle(row2[2], color=GREEN, buff=0.12))
        self.play(Create(boxes), run_time=1)
        until(73)
        difference = math(r"(1+i)PV-PV=A(1-v^n)", 42).move_to([0, -0.85, 0])
        self.play(Write(difference), row1[4].animate.set_color(GREEN), row2[2].animate.set_color(GREEN), run_time=2)
        self.play(FadeOut(row1), FadeOut(row2), FadeOut(boxes), difference.animate.move_to([0, 1.8, 0]), run_time=1)
        simplified = math(r"i\,PV=A(1-v^n)", 42).move_to([0, 0.45, 0])
        final = math(r"PV=\frac{A(1-v^n)}{i}", 48).move_to([0, -1.2, 0])
        self.play(Write(simplified), run_time=1)
        self.play(Write(final), run_time=1)
        self.play(Create(SurroundingRectangle(final, color=ORANGE, buff=0.22)), run_time=1)
        until(84)
        clear()

        # 01:25–01:45: use the supplied precision and totals unchanged.
        heading = txt("代入租屋條件，算出今天的價值", 34).move_to([0, 3.15, 0])
        parameters = math(r"A=1000,\quad i=0.01,\quad n=36", 36, BLUE).move_to([0, 2.05, 0])
        self.play(FadeIn(heading), Write(parameters), run_time=2)
        steps = VGroup(
            math(r"v^{36}=1.01^{-36}\approx0.6989", 32),
            math(r"1-0.6989\approx0.3011", 32),
            math(r"PV=\frac{1000(1-1.01^{-36})}{0.01}", 32),
            math(r"PV\approx30{,}107.51", 39, ORANGE),
        ).arrange(DOWN, buff=0.42).move_to([-3.3, -0.1, 0])
        for step in steps:
            self.play(Write(step), run_time=1.5)
        panel = RoundedRectangle(width=5.8, height=3.3, corner_radius=0.18, stroke_color=BLUE, fill_color=WHITE, fill_opacity=0.55).move_to([3.7, -0.1, 0])
        labels = VGroup(txt("分期合計", 27), txt("一次付清", 27), txt("差額", 27, ORANGE)).arrange(DOWN, aligned_edge=LEFT, buff=0.55).move_to([2.15, -0.1, 0])
        values = VGroup(txt("36,000", 29), txt("30,107.51", 29), txt("5,892.49", 29, ORANGE))
        for value, label in zip(values, labels):
            value.move_to([4.65, label.get_y(), 0])
        self.play(FadeIn(panel), FadeIn(labels), FadeIn(values), run_time=2)
        until(104)
        clear()

        # 01:45–02:00: retirement application; space below remains for ASS.
        retire = ImageMobject(str(ASSETS / "03_retire.jpg")).set_height(4.8).move_to([0, 0.8, 0])
        last_formula = math(r"PV=\frac{A(1-v^n)}{i}", 36, BLUE).move_to([0, -2.05, 0])
        self.play(FadeIn(retire), FadeIn(last_formula), run_time=2)
        until(119)
        clear()
        until(120)
