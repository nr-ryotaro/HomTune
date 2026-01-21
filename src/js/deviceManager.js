export class DeviceManager {
  constructor() {
    this.devices = [];
  }

  setDevices(devices) {
    this.devices = devices;
  }

  getDevices() {
    return this.devices;
  }

  getDeviceById(id) {
    return this.devices.find(device => device.id === id);
  }

  getDevicesByRoom(roomId) {
    return this.devices.filter(device => device.room === roomId);
  }

  calculateYearsOwned(purchaseDate) {
    const purchase = new Date(purchaseDate);
    const today = new Date();
    const diffTime = Math.abs(today - purchase);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return (diffDays / 365).toFixed(1);
  }

  getMaintenanceStatus(device) {
    if (!device.maintenance) return null;
    
    const alerts = device.maintenance.alerts || [];
    const highPriorityAlerts = alerts.filter(a => a.priority === 'high');
    const mediumPriorityAlerts = alerts.filter(a => a.priority === 'medium');
    
    if (highPriorityAlerts.length > 0) {
      return { type: 'warning', message: highPriorityAlerts[0].message };
    } else if (mediumPriorityAlerts.length > 0) {
      return { type: 'info', message: mediumPriorityAlerts[0].message };
    }
    
    return null;
  }

  getWarrantyStatus(device) {
    if (!device.warranty) return null;
    
    const manufacturer = device.warranty.manufacturer;
    if (manufacturer && !manufacturer.expired) {
      const expiryDate = new Date(manufacturer.expiryDate);
      const today = new Date();
      const daysRemaining = Math.ceil((expiryDate - today) / (1000 * 60 * 60 * 24));
      
      if (daysRemaining > 0 && daysRemaining <= 30) {
        return { 
          type: 'info', 
          message: `保証期限まであと${daysRemaining}日`,
          daysRemaining 
        };
      }
    }
    
    return null;
  }
}
