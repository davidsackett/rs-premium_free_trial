#Copyright 2015 RightScale
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.


#RightScale Cloud Application Template (CAT)

# DESCRIPTION
# Deploys a Windows Server of the type chosen by the user.
# It automatically imports the ServerTemplate it needs.
# Also, if needed by the target cloud, the security group and/or ssh key is automatically created by the CAT.


# Required prolog
name 'B) Corporate Standard Windows Server'
rs_ca_ver 20131202
short_description "![logo](https://s3.amazonaws.com/rs-pft/cat-logos/windows.png) 

Get a Windows Server VM in any of our supported public or private clouds"
long_description "Allows you to select different windows server types and cloud and performance level you want.\n
\n
Clouds Supported: <B>AWS, Azure</B>"

##################
# User inputs    #
##################
parameter "param_location" do 
  category "User Inputs"
  label "Cloud" 
  type "string" 
  allowed_values "AWS", "Azure"
  default "AWS"
end

parameter "param_servertype" do
  category "User Inputs"
  label "Windows Server Type"
  type "list"
  allowed_values "Windows 2008R2 Base Server",
  "Windows 2008R2 IIS Server",
  "Windows 2008R2 Server with SQL 2008",
  "Windows 2008R2 Server with SQL 2012",
  "Windows 2012 Base Server",
  "Windows 2012 IIS Server",
  "Windows 2012 Server with SQL 2012"
  default "Windows 2008R2 Base Server"
end

parameter "param_instancetype" do
  category "User Inputs"
  label "Server Performance Level"
  type "list"
  allowed_values "Standard Performance",
    "High Performance"
  default "Standard Performance"
end

parameter "param_username" do 
  category "User Inputs"
  label "Windows Username" 
#  description "Username (will be created)."
  type "string" 
  no_echo "false"
end

parameter "param_password" do 
  category "User Inputs"
  label "Windows Password" 
  description "Minimum at least 8 characters and must contain at least one of each of the following: 
  Uppercase characters, Lowercase characters, Digits 0-9, Non alphanumeric characters [@#\$%^&+=]." 
  type "string" 
  min_length 8
  max_length 32
  # This enforces a stricter windows password complexity in that all 4 elements are required as opposed to just 3.
  allowed_pattern '(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=])'
  no_echo "true"
end


################################
# Outputs returned to the user #
################################
output "rdp_link" do
  label "RDP Link"
  category "Output"
  description "RDP Link to the Windows server."
end

##############
# MAPPINGS   #
##############
mapping "map_cloud" do {
  "AWS" => {
    "cloud" => "EC2 us-west-1",
    "zone" => null, # We don't care which az AWS decides to use.
    "instance_type" => "m3.medium",
    "sg" => '@sec_group',  
    "ssh_key" => "@ssh_key",
    "pg" => null,
    "mci_mapping" => "Public",
  },
  "Azure" => {   
    "cloud" => "Azure East US",
    "zone" => null,
    "instance_type" => "medium",
    "sg" => null, 
    "ssh_key" => null,
    "pg" => "@placement_group",
    "mci_mapping" => "Public",
  },
  "Google" => {
    "cloud" => "Google",
    "zone" => "us-central1-c", # launches in Google require a zone
    "instance_type" => "n1-standard-2",
    "sg" => '@sec_group',  
    "ssh_key" => null,
    "pg" => null,
    "mci_mapping" => "Public",
  },
  "VMware" => {
    "cloud" => "POC vSphere",
    "zone" => "POC-vSphere-Zone-1", # launches in vSphere require a zone being specified  
    "instance_type" => "large",
    "sg" => null, 
    "ssh_key" => "@ssh_key",
    "pg" => null,
    "mci_mapping" => "VMware",
  }
}
end

mapping "map_instancetype" do {
  "Standard Performance" => {
    "AWS" => "m3.medium",
    "Azure" => "medium",
    "Google" => "n1-standard-1",
    "VMware" => "small",
  },
  "High Performance" => {
    "AWS" => "m3.large",
    "Azure" => "large",
    "Google" => "n1-standard-2",
    "VMware" => "large",
  }
} end

mapping "map_st" do {
  "windows_server" => {
    "name" => "Base ServerTemplate for Windows (v13.5.0-LTS)",
    "rev" => "3",
  },
} end
    
mapping "map_mci" do {
  "Windows 2008R2 Base Server" => {
    "mci" => "RightImage_Windows_2008R2_SP1_x64_v13.5.0-LTS",
    "mci_rev" => "2"
  },
  "Windows 2008R2 IIS Server" => {
    "mci" => "RightImage_Windows_2008R2_SP1_x64_iis7.5_v13.5.0-LTS",
    "mci_rev" => "2"
  },
  "Windows 2008R2 Server with SQL 2012" => {
    "mci" => "RightImage_Windows_2008R2_SP1_x64_sqlsvr2012_v13.5.0-LTS",
    "mci_rev" => "2"
  },
  "Windows 2008R2 Server with SQL 2008" => {
    "mci" => "RightImage_Windows_2008R2_SP1_x64_sqlsvr2k8r2_v13.5.0-LTS",
    "mci_rev" => "2"
  },
  "Windows 2012 IIS Server" => {
    "mci" => "RightImage_Windows_2012_x64_iis8_v13.5.0-LTS",
    "mci_rev" => "2"
  },
  "Windows 2012 Server with SQL 2012" => {
    "mci" => "RightImage_Windows_2012_x64_sqlsvr2012_v13.5.0-LTS",
    "mci_rev" => "2"
  },
  "Windows 2012 Base Server" => {
    "mci" => "RightImage_Windows_2012_x64_v13.5.0-LTS",
    "mci_rev" => "2"
  },
} end

##################
# CONDITIONS     #
##################

# Used to decide whether or not to pass an SSH key or security group when creating the servers.
condition "needsSshKey" do
  logic_or(equals?($param_location, "AWS"), equals?($param_location, "VMware"))
end

condition "needsSecurityGroup" do
  logic_or(equals?($param_location, "AWS"), equals?($param_location, "Google"))
end

condition "invSphere" do
  equals?($param_location, "VMware")
end

condition "inAzure" do
  equals?($param_location, "Azure")
end

condition "needsPlacementGroup" do
  equals?($param_location, "Azure")
end 

############################
# RESOURCE DEFINITIONS     #
############################

### Server Definition ###
resource "windows_server", type: "server" do
  name 'Windows Server'
  cloud map($map_cloud, $param_location, "cloud")
  datacenter map($map_cloud, $param_location, "zone")
  server_template_href find(map($map_st, "windows_server", "name"), revision: map($map_st, "windows_server", "rev"))
  multi_cloud_image find(map($map_mci, $param_servertype, "mci"))
  instance_type map($map_instancetype, $param_instancetype, $param_location)
  ssh_key_href map($map_cloud, $param_location, "ssh_key")
  security_group_hrefs map($map_cloud, $param_location, "sg")  
  placement_group_href map($map_cloud, $param_location, "pg")
  inputs do {
    "ADMIN_ACCOUNT_NAME" => join(["text:",$param_username]),
    "ADMIN_PASSWORD" => join(["cred:CAT_WINDOWS_ADMIN_PASSWORD-",@@deployment.href]), # this credential gets created below using the user-provided password.
    "FIREWALL_OPEN_PORTS_TCP" => "text:3389",
    "SYS_WINDOWS_TZINFO" => "text:Pacific Standard Time",  
  } end
end

### Security Group Definitions ###
# Note: Even though not all environments need or use security groups, the launch operation/definition will decide whether or not
# to provision the security group and rules.
resource "sec_group", type: "security_group" do
  condition $needsSecurityGroup

  name join(["WindowsServerSecGrp-",@@deployment.href])
  description "Windows Server security group."
  cloud map( $map_cloud, $param_location, "cloud" )
end

resource "sec_group_rule_rdp", type: "security_group_rule" do
  condition $needsSecurityGroup

  name "Windows Server RDP Rule"
  description "Allow RDP access."
  source_type "cidr_ips"
  security_group @sec_group
  protocol "tcp"
  direction "ingress"
  cidr_ips "0.0.0.0/0"
  protocol_details do {
    "start_port" => "3389",
    "end_port" => "3389"
  } end
end

### SSH Key ###
resource "ssh_key", type: "ssh_key" do
  condition $needsSshKey

  name join(["sshkey_", last(split(@@deployment.href,"/"))])
  cloud map($map_cloud, $param_location, "cloud")
end

### Placement Group ###
resource "placement_group", type: "placement_group" do
  condition $needsPlacementGroup

  name last(split(@@deployment.href,"/"))
  cloud map($map_cloud, $param_location, "cloud")
end 

##################
# Permissions    #
##################
permission "import_servertemplates" do
  actions   "rs.import"
  resources "rs.publications"
end

####################
# OPERATIONS       #
####################

operation "launch" do 
  description "Launch the server"
  definition "pre_auto_launch"
end

operation "enable" do
  description "Get information once the app has been launched"
  definition "enable"
  
  # Update the links provided in the outputs.
   output_mappings do {
     $rdp_link => $server_ip_address,
   } end
end

operation "terminate" do
  description "Terminate the server and clean up"
  definition "terminate_server"
end

operation "Update Server Password" do
  description "Update/reset password."
  definition "update_password"
end


##########################
# DEFINITIONS (i.e. RCL) #
##########################

# Import and set up what is needed for the server and then launch it.
define pre_auto_launch($map_cloud, $param_location, $param_password, $map_st) do
  
  # Need the cloud name later on
  $cloud_name = map( $map_cloud, $param_location, "cloud" )

  # Check if the selected cloud is supported in this account.
  # Since different PIB scenarios include different clouds, this check is needed.
  # It raises an error if not which stops execution at that point.
  call checkCloudSupport($cloud_name, $param_location)
  
  # Find and import the server template - just in case it hasn't been imported to the account already
  call importServerTemplate($map_st)
    
  # Create the Admin Password credential used for the server based on the user-entered password.
  $credname = join(["CAT_WINDOWS_ADMIN_PASSWORD-",@@deployment.href])
  rs.credentials.create({"name":$credname, "value": $param_password})

end

define enable(@windows_server, $inAzure) return $server_ip_address do
  # If deployed in Azure one needs to provide the port mapping that Azure uses.
  if $inAzure
     @bindings = rs.clouds.get(href: @windows_server.current_instance().cloud().href).ip_address_bindings(filter: ["instance_href==" + @windows_server.current_instance().href])
     @binding = select(@bindings, {"private_port":3389})
     $server_ip_address = join([to_s(@windows_server.current_instance().public_ip_addresses[0]),":",@binding.public_port])
  else
     $server_ip_address = @windows_server.current_instance().public_ip_addresses[0]
  end
end 

# post launch action to change the credentials
define update_password(@windows_server, $param_password) do
  task_label("Update the windows server password.")

  if $param_password
    $cred_name = join(["CAT_WINDOWS_ADMIN_PASSWORD-",@@deployment.href])
    # update the credential
    rs.audit_entries.create(audit_entry: {auditee_href: @@deployment.href, summary: join(["Updating credential, ", $cred_name])})
    @cred = rs.credentials.get(filter: join(["name==",$cred_name]))
    @cred.update(credential: {"value" : $param_password})
  end
  
  # Now run the set admin script which will use the newly updated credential.
  $script_name = "SYS Set admin account (v13.5.0-LTS)"
  @script = rs.right_scripts.get(filter: join(["name==",$script_name]))
  $right_script_href=@script.href
  @task = @windows_server.current_instance().run_executable(right_script_href: $right_script_href, inputs: {})
  sleep_until(@task.summary =~ "^(completed|failed)")
  if @task.summary =~ "failed"
    raise "Failed to run " + $right_script_href
  end  
end

# Delete the credential created for the windows password
define terminate_server(@windows_server, @placement_group, $inAzure) do
  
  # Special terminate action taken if launched in Azure to account for Azure cloud clean up.
  if $inAzure
    rs.audit_entries.create(audit_entry: {auditee_href: @@deployment.href, summary: "azure_terminate."})

    delete(@windows_server)

    # Now retry a few times to delete the placement group
    $attempts = 0
    $succeeded = false
    while ($attempts < 30) && ($succeeded == false) do
       sub on_error: skip do
         @placement_group.destroy()
         $succeeded = true
       end
       $attempts = $attempts + 1 
       sleep(5)
    end
    
    rs.audit_entries.create(audit_entry: {auditee_href: @@deployment.href, summary: "azure_terminate: retries:"+to_s($attempts)+"; pg delete success:"+to_s($succeeded)})

  end
  
  # Delete the cred we created for the user-provided password
  $credname = join(["CAT_WINDOWS_ADMIN_PASSWORD-",@@deployment.href])
  @cred=rs.credentials.get(filter: [join(["name==",$credname])])
  @cred.destroy()
  
end

# Checks if the account supports the selected cloud
define checkCloudSupport($cloud_name, $param_location) do
  # Gather up the list of clouds supported in this account.
  @clouds = rs.clouds.get()
  $supportedClouds = @clouds.name[] # an array of the names of the supported clouds
  
  # Check if the selected/mapped cloud is in the list and yell if not
  if logic_not(contains?($supportedClouds, [$cloud_name]))
    raise "Your trial account does not support the "+$param_location+" cloud. Contact RightScale for more information on how to enable access to that cloud."
  end
end

# Imports the server templates found in the given map.
# It assumes a "name" and "rev" mapping
define importServerTemplate($stmap) do
  foreach $st in keys($stmap) do
    $server_template_name = map($stmap, $st, "name")
    $server_template_rev = map($stmap, $st, "rev")
    @pub_st=rs.publications.index(filter: ["name=="+$server_template_name, "revision=="+$server_template_rev])
    @pub_st.import()
  end
end

define handle_retries($attempts) do
  if $attempts < 3
    $_error_behavior = "retry"
    sleep(60)
  else
    $_error_behavior = "skip"
  end
end

