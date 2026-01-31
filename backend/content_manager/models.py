from django.db import models
from django.contrib.auth.models import User
from PIL import Image
from io import BytesIO
from django.core.files.base import ContentFile
import os

class WeeklyForecast(models.Model):
    author = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=200, default="Bu Haftanın Gökyüzü Gündemi")
    week_start = models.DateField()
    week_end = models.DateField()
    content_html = models.TextField(help_text="HTML Content from Editor")
    banner_image = models.ImageField(upload_to='forecast_images/', blank=True, null=True)
    is_published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        if self.banner_image:
            try:
                img = Image.open(self.banner_image)
                if img.mode != 'RGB':
                    img = img.convert('RGB')
                max_width = 1000
                if img.width > max_width:
                    ratio = max_width / img.width
                    new_height = int(img.height * ratio)
                    img = img.resize((max_width, new_height), Image.Resampling.LANCZOS)
                output = BytesIO()
                img.save(output, format='JPEG', quality=80, optimize=True)
                output.seek(0)
                self.banner_image.file = ContentFile(output.read(), name=os.path.splitext(self.banner_image.name)[0] + '.jpg')
            except Exception as e:
                print(f"Image processing failed: {e}")
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.title} ({self.week_start})"
