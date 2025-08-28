sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd

sudo yum install git -y
sudo yum install ansible-core -y
