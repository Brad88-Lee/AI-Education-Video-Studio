from manim import *


class FormulaTest(Scene):
    def construct(self):
        f1 = MathTex(r"\frac{a}{b}").scale(1.5)
        f2 = MathTex(r"x^2 + y^2 = z^2").scale(1.5).next_to(f1, DOWN)
        self.play(Write(f1))
        self.play(Write(f2))
        self.wait(3)
