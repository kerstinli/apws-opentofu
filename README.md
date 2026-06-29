tofu init

export TF_VAR_opensearch_password="dein-sicheres-passwort"
tofu plan -out=tfplan

tofu apply tfplan
