variable "location" {
  type        = string
  description = "The Azure region where the resources should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the AKS cluster."

  validation {
    condition     = can(regex("^[a-zA-Z0-9]$|^[a-zA-Z0-9][-_a-zA-Z0-9]{0,61}[a-zA-Z0-9]$", var.name))
    error_message = "Check naming rules here https://learn.microsoft.com/en-us/rest/api/aks/managed-clusters/create-or-update?view=rest-aks-2023-10-01&tabs=HTTP"
  }
}

variable "network" {
  type = object({
    node_subnet_id       = string
    pod_cidr             = string
    service_cidr         = optional(string)
    api_server_subnet_id = optional(string)
  })
  description = "Values for the networking configuration of the AKS cluster"
}

# This is required for most resource modules
variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
  nullable    = false
}

variable "acr" {
  type = object({
    name                          = string
    private_dns_zone_resource_ids = set(string)
    subnet_resource_id            = string
    zone_redundancy_enabled       = optional(bool)
  })
  default     = null
  description = "(Optional) Parameters for the Azure Container Registry to use with the Kubernetes Cluster."
}

variable "agents_tags" {
  type        = map(string)
  default     = {}
  description = "(Optional) A mapping of tags to assign to the Node Pool."
}

variable "automatic_upgrade_channel" {
  type        = string
  default     = "stable"
  description = <<DESCRIPTION
Specifies the automatic upgrade channel for the cluster. Possible values are:
- `stable`: Ensures the cluster is always in a supported version (i.e., within the N-2 rule).
- `rapid`: Ensures the cluster is always in a supported version on a faster release cadence.
- `patch`: Gets the latest patches as soon as possible.
- `node-image`: Ensures the node image is always up to date.
DESCRIPTION

  validation {
    condition     = can(regex("^(stable|rapid|patch|node-image|none)$", var.automatic_upgrade_channel))
    error_message = "automatic_upgrade_channel must be one of 'stable', 'rapid', 'patch', or 'node-image'.  If not set it will default to `stable`."
  }
}

variable "enable_api_server_vnet_integration" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
  # https://azure.github.io/Azure-Verified-Modules/specs/shared/#id-sfr1---category-composition---preview-services
  THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION

  Enable VNET integration for the AKS cluster

  This requires the following preview feature registered on the subscription:

  az feature register --namespace "Microsoft.ContainerService" --name "EnableAPIServerVnetIntegrationPreview"
DESCRIPTION
}

variable "default_node_pool_vm_sku" {
  type        = string
  default     = "Standard_D4d_v5"
  description = "The VM SKU to use for the default node pool. A minimum of three nodes of 8 vCPUs or two nodes of at least 16 vCPUs is recommended. Do not use SKUs with less than 4 CPUs and 4Gb of memory."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "image_cleaner_enabled" {
  type        = bool
  default     = true
  description = "Enable the image cleaner for the Kubernetes cluster."
}

variable "image_cleaner_interval_hours" {
  type        = number
  default     = 168
  description = "Interval in hours for the image cleaner to run."
}

variable "keda_enabled" {
  type        = bool
  default     = true
  description = "Enable KEDA for the Kubernetes cluster."
}

variable "kubernetes_version" {
  type        = string
  default     = null
  description = "Specify which Kubernetes release to use. Specify only minor version, such as '1.28'."
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
  Controls the Resource Lock configuration for this resource. The following properties can be specified:

  - `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
  - `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.
  DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "maintenance_window_auto_upgrade" {
  type = object({
    day_of_month = optional(number)
    day_of_week  = optional(string)
    duration     = optional(number, 4)
    frequency    = optional(string)
    interval     = optional(number, 1)
    start_date   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    week_index   = optional(string)
    not_allowed = optional(set(object({
      end   = string
      start = string
    })))
  })
  default     = null
  description = <<DESCRIPTION
 - `day_of_month` - (Optional) The day of the month for the maintenance run. Required in combination with RelativeMonthly frequency. Value between 0 and 31 (inclusive).
 - `day_of_week` - (Optional) The day of the week for the maintenance run. Options are `Monday`, `Tuesday`, `Wednesday`, `Thurday`, `Friday`, `Saturday` and `Sunday`. Required in combination with weekly frequency.
 - `duration` - (Required) The duration of the window for maintenance to run in hours.
 - `frequency` - (Required) Frequency of maintenance. Possible options are `Weekly`, `AbsoluteMonthly` and `RelativeMonthly`.
 - `interval` - (Required) The interval for maintenance runs. Depending on the frequency this interval is week or month based.
 - `start_date` - (Optional) The date on which the maintenance window begins to take effect.
 - `start_time` - (Optional) The time for maintenance to begin, based on the timezone determined by `utc_offset`. Format is `HH:mm`.
 - `utc_offset` - (Optional) Used to determine the timezone for cluster maintenance.
 - `week_index` - (Optional) The week in the month used for the maintenance run. Options are `First`, `Second`, `Third`, `Fourth`, and `Last`.

 ---
 `not_allowed` block supports the following:
 - `end` - (Required) The end of a time span, formatted as an RFC3339 string.
 - `start` - (Required) The start of a time span, formatted as an RFC3339 string.

Example input:

maintenance_window_auto_upgrade = {
    duration     = 8
    interval     = 1
    day_of_month = 1
    day_of_week  = "Monday"
    start_date   = "2024-12-01"
    start_time   = "00:00"
    frequency    = "Weekly"
    duration     = "PT1H"
    week_index   = 1
    utcoffset    = "+00:00"
  }

DESCRIPTION
}

variable "maintenance_window_node_os" {
  type = object({
    day_of_month = optional(number)
    day_of_week  = optional(string)
    duration     = optional(number, 4)
    frequency    = optional(string)
    interval     = optional(number, 1)
    start_date   = optional(string)
    start_time   = optional(string)
    utc_offset   = optional(string)
    week_index   = optional(string)
    not_allowed = optional(set(object({
      end   = string
      start = string
    })))
  })
  default     = null
  description = <<DESCRIPTION
 - `day_of_month` - (Optional) The day of the month for the maintenance run. Required in combination with RelativeMonthly frequency. Value between 0 and 31 (inclusive).
 - `day_of_week` - (Optional) The day of the week for the maintenance run. Options are `Monday`, `Tuesday`, `Wednesday`, `Thurday`, `Friday`, `Saturday` and `Sunday`. Required in combination with weekly frequency.
 - `duration` - (Required) The duration of the window for maintenance to run in hours.  Valid values are between 4 and 24 (inclusive).
 - `frequency` - (Required) Frequency of maintenance. Possible options are `Daily`, `Weekly`, `AbsoluteMonthly` and `RelativeMonthly`.
 - `interval` - (Required) The interval for maintenance runs. Depending on the frequency this interval is week or month based.  E.g. a value of 2 for a weekly frequency means maintenance will run every 2 weeks.
 - `start_date` - (Optional) The date on which the maintenance window begins to take effect.
 - `start_time` - (Optional) The time for maintenance to begin, based on the timezone determined by `utc_offset`. Format is `HH:mm`.
 - `utc_offset` - (Optional) Used to determine the timezone for cluster maintenance.  Format is `+HH:MM` or `-HH:MM`.
 - `week_index` - (Optional) The week in the month used for the maintenance run. Options are `First`, `Second`, `Third`, `Fourth`, and `Last`.

 ---
 `not_allowed` block supports the following:
 - `end` - (Required) The end of a time span, formatted as an RFC3339 string.
 - `start` - (Required) The start of a time span, formatted as an RFC3339 string.
Configuration for the maintenance window node OS.

Example input:

maintenance_window_node_os = {
    duration     = 8
    interval     = 1
    day_of_month = 1
    day_of_week  = "Monday"
    start_date   = "2024-12-01"
    start_time   = "00:00"
    frequency    = "Weekly"
    week_index   = 1
    utcoffset    = "+00:00"
  }

DESCRIPTION
}

# tflint-ignore: terraform_unused_declarations
variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "max_count_default_node_pool" {
  type        = number
  default     = 9
  description = "The maximum number of nodes in the default node pool."
}

variable "microsoft_defender_log_analytics_resource_id" {
  type        = string
  default     = null # TODO probably should be 'true' but may not work with E2E testing.
  description = "Enable Microsoft Defender for the Kubernetes cluster."
}

variable "monitor_metrics" {
  type = object({
    annotations_allowed = optional(string)
    labels_allowed      = optional(string)
  })
  default     = null
  description = <<-EOT
  (Optional) Specifies a Prometheus add-on profile for the Kubernetes Cluster
  object({
    annotations_allowed = "(Optional) Specifies a comma-separated list of Kubernetes annotation keys that will be used in the resource's labels metric."
    labels_allowed      = "(Optional) Specifies a Comma-separated list of additional Kubernetes label keys that will be used in the resource's labels metric."
  })
EOT
}

variable "network_policy" {
  type        = string
  default     = "cilium"
  description = <<DESCRIPTION
  The Network Policy to use for this Kubernetes Cluster. Possible values are `azure`, `calico`, or `cilium`. Defaults to `cilium`.
  DESCRIPTION

  validation {
    condition     = can(regex("^(azure|calico|cilium)$", var.network_policy))
    error_message = "network_policy must be either azure, calico, or cilium."
  }
}

variable "node_labels" {
  type        = map(string)
  default     = {}
  description = "(Optional) A map of Kubernetes labels which should be applied to nodes in this Node Pool."
}

variable "node_pools" {
  type = map(object({
    name                 = string
    vm_size              = string
    orchestrator_version = string
    # do not add nodecount because we enforce the use of auto-scaling
    max_count       = optional(number)
    min_count       = optional(number)
    os_sku          = optional(string, "AzureLinux")
    mode            = optional(string)
    os_disk_size_gb = optional(number, null)
    tags            = optional(map(string), {})
    labels          = optional(map(string), {})
    zones           = optional(set(string), ["1", "2", "3"])
  }))
  default     = {}
  description = <<-EOT
A map of node pools that need to be created and attached on the Kubernetes cluster. The key of the map can be the name of the node pool, and the key must be static string. The value of the map is a `node_pool` block as defined below:
map(object({
  name                 = (Required) The name of the Node Pool which should be created within the Kubernetes Cluster. Changing this forces a new resource to be created. A Windows Node Pool cannot have a `name` longer than 6 characters. A random suffix of 4 characters is always added to the name to avoid clashes during recreates.
  vm_size              = (Required) The SKU which should be used for the Virtual Machines used in this Node Pool. Changing this forces a new resource to be created.
  orchestrator_version = (Required) The version of Kubernetes which should be used for this Node Pool. Changing this forces a new resource to be created.
  max_count            = (Optional) The maximum number of nodes which should exist within this Node Pool. Valid values are between `0` and `1000` and must be greater than or equal to `min_count`.
  min_count            = (Optional) The minimum number of nodes which should exist within this Node Pool. Valid values are between `0` and `1000` and must be less than or equal to `max_count`.
  os_sku               = (Optional) Specifies the OS SKU used by the agent pool. Possible values include: `Ubuntu`or `AzureLinux`. If not specified, the default is `AzureLinux`. Changing this forces a new resource to be created.
  mode                 = (Optional) Should this Node Pool be used for System or User resources? Possible values are `System` and `User`. Defaults to `User`.
  os_disk_size_gb      = (Optional) The Agent Operating System disk size in GB. Changing this forces a new resource to be created.
  tags                 = (Optional) A mapping of tags to assign to the resource. At this time there's a bug in the AKS API where Tags for a Node Pool are not stored in the correct case - you [may wish to use Terraform's `ignore_changes` functionality to ignore changes to the casing](https://www.terraform.io/language/meta-arguments/lifecycle#ignore_changess) until this is fixed in the AKS API.
  labels               = (Optional) A map of Kubernetes labels which should be applied to nodes in this Node Pool.
  node_taints          = (Optional) A list of the taints added to new nodes during node pool create and scale.
  zones                = (Optional) A list of Availability Zones across which the Node Pool should be spread. Changing this forces a new resource to be created.
}))

Example input:
```terraform
  node_pools = {
    workload = {
      name                 = "workload"
      vm_size              = "Standard_D2d_v5"
      orchestrator_version = "1.28"
      max_count            = 110
      min_count            = 2
      os_sku               = "Ubuntu"
      mode                 = "User"
    },
    ingress = {
      name                 = "ingress"
      vm_size              = "Standard_D2d_v5"
      orchestrator_version = "1.28"
      max_count            = 4
      min_count            = 2
      os_sku               = "Ubuntu"
      mode                 = "User"
    }
  }
  ```
EOT
  nullable    = false

  validation {
    condition     = alltrue([for pool in var.node_pools : contains(["Ubuntu", "AzureLinux"], pool.os_sku)])
    error_message = "os_sku must be either Ubuntu or AzureLinux"
  }
}

variable "orchestrator_version" {
  type        = string
  default     = null
  description = "Specify which Kubernetes release to use. Specify only minor version, such as '1.28'."
}

variable "os_sku" {
  type        = string
  default     = "AzureLinux"
  description = "(Optional) Specifies the OS SKU used by the agent pool. Possible values include: `Ubuntu` or `AzureLinux`. If not specified, the default is `AzureLinux`.Changing this forces a new resource to be created."

  validation {
    condition     = can(regex("^(Ubuntu|AzureLinux)$", var.os_sku))
    error_message = "os_sku must be either Ubuntu or AzureLinux"
  }
}

variable "private_dns_zone_id" {
  type        = string
  default     = null
  description = "(Optional) Either the ID of Private DNS Zone which should be delegated to this Cluster."

  validation {
    condition     = var.private_dns_zone_id == null || can(regex("^(/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/[^/]+)$", var.private_dns_zone_id))
    error_message = "private_dns_zone_id must be a valid Private DNS Zone ID"
  }
}

variable "private_dns_zone_id_api_server" {
  type        = string
  default     = null
  description = "(Optional) The ID of Private DNS Zone used by the API server."

  validation {
    condition     = var.private_dns_zone_id_api_server == null || can(regex("^(/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft.Network/privateDnsZones/[^/]+)$", var.private_dns_zone_id_api_server))
    error_message = "private_dns_zone_id_api_server must be a valid Private DNS Zone ID"
  }
}

variable "private_dns_zone_set_rbac_permissions" {
  type        = bool
  default     = false
  description = "(Optional) Enable private DNS zone integration for the AKS cluster."
  nullable    = false
}

variable "rbac_aad_admin_group_object_ids" {
  type        = list(string)
  default     = null
  description = "Object ID of groups with admin access."
}

variable "rbac_aad_azure_rbac_enabled" {
  type        = bool
  default     = true
  description = "(Optional) Is Role Based Access Control based on Azure AD enabled?"
}

variable "rbac_aad_tenant_id" {
  type        = string
  default     = null
  description = "(Optional) The Tenant ID used for Azure Active Directory Application. If this isn't specified the Tenant ID of the current Subscription is used."
}

# tflint-ignore: terraform_unused_declarations
variable "tags" {
  type        = map(string)
  default     = null
  description = "(Optional) Tags of the resource."
}

variable "user_assigned_identity_name" {
  type        = string
  default     = null
  description = "(Optional) The name of the User Assigned Identity which should be assigned to the Kubernetes Cluster."
}

variable "vertical_pod_autoscaler_enabled" {
  type        = bool
  default     = true
  description = "Enable Vertical Pod Autoscaler for the Kubernetes cluster."
}

variable "vnet_set_rbac_permissions" {
  type        = bool
  default     = true
  description = "(Optional) Whether to create Network Contributor RBAC on the supplied subnets"
  nullable    = false
}

variable "ingress_profile" {
  type = object({
    dns_zone_resource_ids = list(string)
    enabled               = optional(bool, true)
    nginx = object({
      default_ingress_controller_type = string
    })
  })
  default     = null
  description = <<DESCRIPTION
  # https://azure.github.io/Azure-Verified-Modules/specs/shared/#id-sfr1---category-composition---preview-services
  THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION

  Configuration for the ingress profile that will be used to configure web application routing extension for the AKS cluster.
DESCRIPTION

  validation {
    condition     = var.ingress_profile == null || try(contains(["AnnotationControlled", "External", "Internal", "None"], var.ingress_profile.nginx.default_ingress_controller_type), false)
    error_message = "The default_ingress_controller_type must be one of `AnnotationControlled`, `External`, `Internal`, or `None`."
  }
}

variable "safeguard_profile" {
  type = object({
    level               = string
    version             = string
    excluded_namespaces = optional(list(string))
  })
  default     = null
  description = <<DESCRIPTION
  # https://azure.github.io/Azure-Verified-Modules/specs/shared/#id-sfr1---category-composition---preview-services
  THIS IS A VARIABLE USED FOR A PREVIEW SERVICE/FEATURE, MICROSOFT MAY NOT PROVIDE SUPPORT FOR THIS, PLEASE CHECK THE PRODUCT DOCS FOR CLARIFICATION

  Configuration for the safeguard profile that will warning or block the deployment of resources that are not compliant with the Azure policies. 

  safeguard_profile = {
    level = "Warning",
    version = "v1.0.0",
    excluded_namespaces = [
      "kube-system",
      "calico-system",
      "tigera-system",
      "gatekeeper-system"
    ]
  }

DESCRIPTION

  validation {
    condition     = var.safeguard_profile == null || try(contains(["Enforcement", "Warning", "Off"], var.safeguard_profile.level), false)
    error_message = "The level must be one of `Enforcement`, `Warning`, or `Off`."
  }
}
