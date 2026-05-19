resource "kubectl_manifest" "efs_storage_class" {
  yaml_body = <<-YAML
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: efs-sc
    provisioner: efs.csi.aws.com
    parameters:
      provisioningMode: efs-ap
      fileSystemId: ${aws_efs_file_system.main.id}
      directoryPerms: "700"
  YAML

  # Ensures infrastructure mount points are live before registering the storage tier
  depends_on = [
    aws_efs_mount_target.main
  ]
}