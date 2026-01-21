import { DeviceManager } from './deviceManager.js';

export class UI {
  constructor() {
    this.deviceManager = new DeviceManager();
  }

  renderDeviceList(devices, roomName = null) {
    const container = document.getElementById('device-list');
    if (!container) return;

    // ヘッダーを更新
    const header = container.parentElement.querySelector('h2');
    if (header && roomName) {
      header.textContent = `デバイス一覧 - ${roomName}`;
    } else if (header) {
      header.textContent = 'デバイス一覧';
    }

    if (devices.length === 0) {
      container.innerHTML = `
        <div class="bg-white border border-homtune-border rounded-sm p-8 text-center">
          <p class="text-sm text-homtune-secondary">この部屋にはデバイスが登録されていません</p>
        </div>
      `;
    } else {
      container.innerHTML = devices.map(device => this.createDeviceCard(device)).join('');
    }
  }

  createDeviceCard(device) {
    const maintenanceStatus = this.getMaintenanceStatus(device);
    const warrantyStatus = this.getWarrantyStatus(device);
    const yearsOwned = this.calculateYearsOwned(device.purchaseDate);
    
    const alertBadges = [];
    if (maintenanceStatus) {
      alertBadges.push(`
        <span class="alert-badge ${maintenanceStatus.type}">
          ${maintenanceStatus.message}
        </span>
      `);
    }
    if (warrantyStatus) {
      alertBadges.push(`
        <span class="alert-badge ${warrantyStatus.type}">
          ${warrantyStatus.message}
        </span>
      `);
    }

    return `
      <div class="device-card" data-device-id="${device.id}">
        <div class="flex items-start justify-between mb-4">
          <div class="flex-1">
            <div class="flex items-center space-x-3 mb-2">
              <h3 class="text-lg font-light">${device.name}</h3>
              ${alertBadges.join('')}
            </div>
            <p class="text-sm text-homtune-secondary mb-1">${device.manufacturer} ${device.modelNumber}</p>
            <p class="text-xs text-homtune-secondary">${device.room} · 購入から ${yearsOwned}年</p>
          </div>
          <div class="ml-4">
            <button class="text-homtune-secondary hover:text-homtune-accent transition-colors">
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 5v.01M12 12v.01M12 19v.01M12 6a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2zm0 7a1 1 0 110-2 1 1 0 010 2z" />
              </svg>
            </button>
          </div>
        </div>
        
        <div class="grid grid-cols-2 gap-4 mt-4 pt-4 border-t border-homtune-border">
          <div>
            <p class="text-xs text-homtune-secondary mb-1">資産価値</p>
            <p class="text-sm font-light">¥${device.assetValue?.currentUsedPrice?.toLocaleString() || 'N/A'}</p>
          </div>
          <div>
            <p class="text-xs text-homtune-secondary mb-1">最終メンテナンス</p>
            <p class="text-sm font-light">${device.maintenance?.lastMaintenance || '未実施'}</p>
          </div>
        </div>
        
        <div class="flex items-center justify-end space-x-3 mt-4">
          <a href="${device.manual?.url || '#'}" target="_blank" class="text-xs text-homtune-secondary hover:text-homtune-accent transition-colors">
            説明書を見る →
          </a>
          <button class="text-xs text-homtune-primary hover:text-homtune-accent border border-homtune-border px-3 py-1 rounded-sm transition-colors">
            詳細
          </button>
        </div>
      </div>
    `;
  }

  getMaintenanceStatus(device) {
    if (!device.maintenance?.alerts || device.maintenance.alerts.length === 0) {
      return null;
    }
    
    const highPriorityAlert = device.maintenance.alerts.find(a => a.priority === 'high');
    if (highPriorityAlert) {
      return { type: 'warning', message: highPriorityAlert.message };
    }
    
    const mediumPriorityAlert = device.maintenance.alerts.find(a => a.priority === 'medium');
    if (mediumPriorityAlert) {
      return { type: 'info', message: mediumPriorityAlert.message };
    }
    
    return null;
  }

  getWarrantyStatus(device) {
    if (!device.warranty?.manufacturer) return null;
    
    const manufacturer = device.warranty.manufacturer;
    if (!manufacturer.expired) {
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

  calculateYearsOwned(purchaseDate) {
    const purchase = new Date(purchaseDate);
    const today = new Date();
    const diffTime = Math.abs(today - purchase);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return (diffDays / 365).toFixed(1);
  }
}
