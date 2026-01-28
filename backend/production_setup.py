import os
import subprocess
import secrets

def run_command(command):
    print(f"Executing: {command}")
    try:
        subprocess.check_call(command, shell=True)
        print("Success.")
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        exit(1)

def create_env_file():
    print("Generating .env file for production...")
    # Generate a random 50-char secret key
    secret_key = secrets.token_urlsafe(50)
    
    env_content = f"""
DEBUG=False
SECRET_KEY={secret_key}
ALLOWED_HOSTS=astrorehberi.com,www.astrorehberi.com,localhost,127.0.0.1
CSRF_TRUSTED_ORIGINS=https://astrorehberi.com,https://www.astrorehberi.com
"""
    with open(".env", "w") as f:
        f.write(env_content.strip())
    print(".env file created.")

def create_superuser():
    print("Creating Superuser (admin)...")
    # Command to run inside the container
    # Checks if user exists, if not creates it
    py_script = (
        "from django.contrib.auth import get_user_model; "
        "User = get_user_model(); "
        "User.objects.filter(username='admin').exists() or "
        "User.objects.create_superuser('admin', 'admin@astrorehberi.com', 'Yakut18!')"
    )
    
    cmd = f'docker-compose exec -T web python manage.py shell -c "{py_script}"'
    run_command(cmd)

def main():
    print("--- STARTING PRODUCTION DEPLOYMENT SETUP ---")
    
    # 1. Create .env
    if not os.path.exists(".env"):
        create_env_file()
    else:
        print(".env already exists. Skipping.")

    # 2. Build and Start Docker Containers
    print("Building and starting Docker containers...")
    run_command("docker-compose up -d --build")

    # 3. Apply Migrations
    print("Applying database migrations...")
    run_command("docker-compose exec -T web python manage.py migrate")
    
    # 4. Collect Static
    print("Collecting static files...")
    run_command("docker-compose exec -T web python manage.py collectstatic --noinput")

    # 5. Create Superuser
    create_superuser()

    print("\n--- DEPLOYMENT SETUP COMPLETE ---")
    print("1. Please run the Certbot command (step 4 in deploy_aws.md) to get SSL.")
    print("2. Then update nginx/default.conf with the SSL config.")
    print("3. Restart nginx: docker-compose restart nginx")

if __name__ == "__main__":
    main()
