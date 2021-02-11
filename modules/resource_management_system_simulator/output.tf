output "public_ip" {
  description = "ID of the simulator instance"
  value       = aws_instance.simulator.public_ip
}


output "transit_gateway" {
  description = "The transit gateway of the RMS"
  value = data.aws_ec2_transit_gateway.rms_transit_gateway
}