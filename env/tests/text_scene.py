from manim import *


class ChineseText(Scene):
    def construct(self):
        title = Text("小明存錢", font="Noto Sans CJK TC", font_size=56)
        sub = Text("Hello 123", font="Noto Sans CJK TC", font_size=40).next_to(title, DOWN)
        self.play(Write(title))
        self.play(FadeIn(sub))
        self.wait(3)
