from django.db import models
from django.utils.text import slugify

class LibraryCategory(models.Model):
    name = models.CharField(max_length=100)
    slug = models.SlugField(unique=True, blank=True)
    icon = models.CharField(max_length=50, default='fas fa-book') # FontAwesome Class
    order = models.IntegerField(default=0)

    class Meta:
        ordering = ['order', 'name']
        verbose_name_plural = "Library Categories"

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name

class LibraryItem(models.Model):
    category = models.ForeignKey(LibraryCategory, on_delete=models.CASCADE, related_name='items')
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True, blank=True)
    short_desc = models.TextField(blank=True, help_text="Listelendiğinde görünecek kısa özet")
    content = models.TextField(help_text="HTML Destekli İçerik")
    image_url = models.CharField(max_length=500, blank=True, null=True)
    
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # Metadata for specific lookups (e.g. 'aries', 'fool_card')
    lookup_key = models.CharField(max_length=50, blank=True, null=True, db_index=True)

    class Meta:
        ordering = ['category', 'title']

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.title)
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.category.name} - {self.title}"
