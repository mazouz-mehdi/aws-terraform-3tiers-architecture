terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "projet-terraform-state-mehdi-123"
    key            = "projet-vpc/terraform.tfstate"
    region         = "eu-west-3"
    dynamodb_table = "terraform-state-lock-mehdi"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-3" # Région de Paris
}

# 1. Le réseau virtuel (VPC)
resource "aws_vpc" "mon_vpc" {
  cidr_block           = "10.0.0.0/16" # Plage de 65 536 adresses IP privées
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Projet-VPC-Mehdi"
  }
}

# 2. La porte de sortie vers Internet (Internet Gateway)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.mon_vpc.id

  tags = {
    Name = "Porte-Internet-Mehdi"
  }
}

# 3. Le sous-réseau PUBLIC (accessible depuis le web)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.mon_vpc.id
  cidr_block              = "10.0.1.0/24" # Plage de 256 adresses IP
  availability_zone       = "eu-west-3a"  # Déployé dans la zone A de Paris
  map_public_ip_on_launch = true          # Donne une IP publique automatiquement

  tags = {
    Name = "Sous-Reseau-Public"
  }
}

# 4. Table de routage pour diriger le trafic public vers Internet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.mon_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Table-Routage-Publique"
  }
}

# 5. Association de la table de routage au sous-réseau public
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# 6. Le sous-réseau PRIVÉ (isolé du web, pour la sécurité)
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.mon_vpc.id
  cidr_block              = "10.0.2.0/24" # Plage de 256 adresses IP
  availability_zone       = "eu-west-3b"  # Déployé dans la zone B pour la résilience

  tags = {
    Name = "Sous-Reseau-Prive"
  }
}
# 7. Bucket S3 pour stocker l'état Terraform (le tfstate)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "projet-terraform-state-mehdi-123" # Remplace XYZ par 3 chiffres au hasard
  
  lifecycle {
    prevent_destroy = false
  }
}

# 8. Table DynamoDB pour verrouiller l'état (Locking)
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock-mehdi"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
# 9. Pare-feu du Load Balancer (ouvert sur Internet)
resource "aws_security_group" "alb_sg" {
  name        = "alb-security-group"
  description = "Autorise le trafic HTTP entrant depuis Internet"
  vpc_id      = aws_vpc.mon_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 10. Pare-feu des serveurs Web (ouvert UNIQUEMENT au Load Balancer)
resource "aws_security_group" "web_sg" {
  name        = "web-servers-sg"
  description = "Autorise le trafic web venant uniquement du Load Balancer"
  vpc_id      = aws_vpc.mon_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Sécurité maximale : lien direct avec l'ALB
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# 11. Deuxième sous-réseau public (Exigence technique de l'ALB)
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.mon_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "eu-west-3c" # Zone C
  map_public_ip_on_launch = true
}

# 12. Connecter ce 2ème réseau à Internet
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# 13. Le Load Balancer (Point d'entrée public)
resource "aws_lb" "web_alb" {
  name               = "web-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id]
}

# 14. Le Groupe Cible (Où le Load Balancer doit-il envoyer le trafic ?)
resource "aws_lb_target_group" "web_tg" {
  name     = "web-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.mon_vpc.id
}

# 15. L'écouteur (Fait le lien entre le Load Balancer et le Groupe Cible)
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# 16. Récupérer l'ID officiel d'Ubuntu
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 17. Le modèle de lancement AVEC automatisation
resource "aws_launch_template" "web_template" {
  name_prefix   = "web-server-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  # Script magique : installation d'Apache au démarrage
  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apache2
              systemctl start apache2
              systemctl enable apache2
              echo "<h1>Projet DevOps Mehdi : Architecture Haute Disponibilite !</h1>" > /var/www/html/index.html
              EOF
  )
}

# 18. Le groupe d'Auto Scaling (Gère les serveurs dans le réseau privé)
resource "aws_autoscaling_group" "web_asg" {
  name                = "web-auto-scaling-group"
  vpc_zone_identifier = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_2.id] # Les serveurs sont invisibles d'Internet !
  target_group_arns   = [aws_lb_target_group.web_tg.arn]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2 # On veut toujours 2 serveurs actifs

  launch_template {
    id      = aws_launch_template.web_template.id
    version = "$Latest"
  }
}

# 19. Afficher l'adresse URL du Load Balancer à la fin
output "url_load_balancer" {
  value = aws_lb.web_alb.dns_name
}