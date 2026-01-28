from django import forms
from .models import UserProfile

class UserSettingsForm(forms.ModelForm):
    class Meta:
        model = UserProfile
        fields = ['birth_date', 'birth_time', 'lat', 'lon']
        widgets = {
            'birth_date': forms.DateInput(attrs={'type': 'date', 'class': 'form-control'}),
            'birth_time': forms.TimeInput(attrs={'type': 'time', 'class': 'form-control'}),
            'lat': forms.NumberInput(attrs={'step': '0.0001', 'class': 'form-control'}),
            'lon': forms.NumberInput(attrs={'step': '0.0001', 'class': 'form-control'}),
        }
        labels = {
            'birth_date': 'Doğum Tarihi',
            'birth_time': 'Doğum Saati',
            'lat': 'Enlem (Latitude)',
            'lon': 'Boylam (Longitude)',
        }
