# ☁️ Architecture AWS 3-Tiers Haute Disponibilité avec Terraform

Bienvenue sur le dépôt de mon projet d'infrastructure Cloud ! 

Ce projet personnel est le fruit de ma curiosité et de ma volonté de monter en compétences sur les technologies Cloud et DevOps. Il démontre ma capacité à initialiser, sécuriser et déployer de A à Z une infrastructure  sur Amazon Web Services (AWS) via l'approche "Infrastructure as Code" (IaC).

## 🎯 Objectifs du projet
- **Sécurité (Zero Trust) :** Conception d'un VPC sur-mesure avec segmentation stricte (sous-réseaux publics/privés).
- **Haute Disponibilité :** Déploiement d'un Application Load Balancer (ALB) couplé à un Auto Scaling Group (ASG) multi-zones.
- **Automatisation (Zero-Touch) :** Provisioning autonome des serveurs web (Apache) au démarrage via un script `user_data`.
- **Travail Collaboratif :** Externalisation de l'état Terraform (Remote State) sur Amazon S3 avec verrouillage via DynamoDB (State Locking).
- **FinOps :** Automatisation du cycle de vie et destruction complète des ressources pour garantir une facturation à 0€.

## 🛠️ Technologies & Outils
- **Cloud Provider :** AWS (IAM, VPC, EC2, ALB, ASG, S3, DynamoDB)
- **IaC :** Terraform (HCL)
- **Tooling :** AWS CLI, Visual Studio Code, Git

## 📄 Fichiers du projet
Vous trouverez dans ce dépôt :
1. Le fichier `main.tf` contenant l'intégralité de mon code source.
2. Mon **rapport de projet complet au format PDF**, qui inclut le détail de mes configurations de sécurité, les preuves de déploiement et ma gestion des incidents (troubleshooting).

---
*Projet réalisé par Mehdi - www.linkedin.com/in/mehdi-mazouz-936536205
