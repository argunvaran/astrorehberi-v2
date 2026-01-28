from django.db import models
from django.contrib.auth.models import User

class WeeklyForecast(models.Model):
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=200, default="Bu Haftanın Gökyüzü Gündemi")
    week_start = models.DateField()
    week_end = models.DateField()
    content_html = models.TextField(help_text="HTML Content from Editor")
    is_published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.title} ({self.week_start})"
