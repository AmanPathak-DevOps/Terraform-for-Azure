variable "vn-name" {
  default = "VN-For-Windows"
}
variable "address-vn" {
  default = "10.0.0.0/16"
}
variable "subnet1" {
  default = "Subnet-For-Windows"
}
variable "subnet-address" {
  default = "10.0.1.0/24"
}
variable "nic-name" {
  default = "Windows-NIC"
}
variable "sg-name" {
  default = "sg-for-windowsvm"
}
variable "env" {
  default = "Development"
}
variable "vm-name" {
  default = "Windows-VM"
}
variable "usrname" {
  default = "newroot"
}
variable "passwd" {
  default = "newroot@123"
}