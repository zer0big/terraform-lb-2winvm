resource "azurerm_windows_virtual_machine" "zero-vm1" {
  name                = "web-win-vm1"
  resource_group_name = azurerm_resource_group.zero-rg.name
  location            = azurerm_resource_group.zero-rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = data.azurerm_key_vault_secret.kv_secret_web.value
  network_interface_ids = [
    azurerm_network_interface.zero-nic1.id,
  ]
  availability_set_id = azurerm_availability_set.zero-as.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.zero-nic1,
    azurerm_availability_set.zero-as
  ]
}

resource "azurerm_managed_disk" "zero-mdisk1" {
  name                 = "web1-data-disk"
  location             = azurerm_resource_group.zero-rg.location
  resource_group_name  = azurerm_resource_group.zero-rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"
}

resource "azurerm_virtual_machine_data_disk_attachment" "zero-disk1_attatch" {
  managed_disk_id    = azurerm_managed_disk.zero-mdisk1.id
  virtual_machine_id = azurerm_windows_virtual_machine.zero-vm1.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_network_interface" "zero-nic1" {
  name                = "web-nic1"
  location            = azurerm_resource_group.zero-rg.location
  resource_group_name = azurerm_resource_group.zero-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.web-subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    azurerm_virtual_network.zero-vnet,
    azurerm_subnet.web-subnet
  ]
}

resource "azurerm_virtual_machine_extension" "zero-vm1_extension" {
  name                 = "webvm-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.zero-vm1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  depends_on = [
    azurerm_storage_blob.zero-blob
  ]

  settings = <<SETTINGS
    {
      "fileUris": ["https://${azurerm_storage_account.zero-sa.name}.blob.core.windows.net/data/IIS_Config.ps1"],
      "commandToExecute": "powershell.exe -ExecutionPolicy Unrestricted -file \"./IIS_Config.ps1\""
    }
SETTINGS
}