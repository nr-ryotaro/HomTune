import { DeviceManager } from './deviceManager.js';
import { FloorPlanRenderer } from './floorPlan.js';
import { UI } from './ui.js';
import { CapacitorService } from './capacitor.js';

// Initialize application
class App {
  constructor() {
    this.deviceManager = new DeviceManager();
    this.floorPlanRenderer = new FloorPlanRenderer();
    this.ui = new UI();
    this.currentFilterRoom = null; // 現在フィルタリング中の部屋ID
    this.init();
  }

  async init() {
    try {
      // Initialize Capacitor (モバイルアプリの場合のみ)
      try {
        await CapacitorService.initialize();
      } catch (error) {
        console.warn('Capacitor initialization failed (running in browser):', error);
      }
      
      // Load mock data
      const response = await fetch('/mock-data.json');
      if (!response.ok) {
        throw new Error(`Failed to load mock data: ${response.status} ${response.statusText}`);
      }
      const data = await response.json();
      
      // Initialize components
      this.deviceManager.setDevices(data.devices);
      this.floorPlanRenderer.setFloorPlan(data.floorPlan);
      this.floorPlanRenderer.setDevices(data.devices);
      
      // Render UI
      this.render();
      
      // モバイル向けのイベントリスナー設定
      this.setupMobileEvents();
    } catch (error) {
      console.error('Failed to initialize app:', error);
      // エラー表示
      this.showError(error);
    }
  }

  showError(error) {
    const main = document.querySelector('main');
    if (main) {
      main.innerHTML = `
        <div class="max-w-7xl mx-auto px-6 py-8">
          <div class="bg-red-50 border border-red-200 rounded-sm p-6">
            <h2 class="text-lg font-light text-red-800 mb-2">エラーが発生しました</h2>
            <p class="text-sm text-red-600 mb-4">${error.message}</p>
            <p class="text-xs text-red-500">コンソールで詳細を確認してください。</p>
          </div>
        </div>
      `;
    }
  }

  setupMobileEvents() {
    // モバイルメニューボタン
    const mobileMenuBtn = document.getElementById('mobile-menu-btn');
    if (mobileMenuBtn) {
      mobileMenuBtn.addEventListener('click', () => {
        // モバイルメニューの実装（将来拡張）
        console.log('Mobile menu clicked');
      });
    }

    // デバイス追加ボタン
    const addDeviceBtn = document.getElementById('add-device-btn');
    if (addDeviceBtn) {
      addDeviceBtn.addEventListener('click', () => {
        // デバイス追加画面への遷移（将来実装）
        console.log('Add device clicked');
      });
    }
  }

  render() {
    // Render device list
    const devices = this.deviceManager.getDevices();
    this.ui.renderDeviceList(devices);
    
    // 部屋クリック時のコールバックを設定
    this.floorPlanRenderer.setOnRoomClick((roomId) => {
      this.filterDevicesByRoom(roomId);
    });
    
    // Render floor plan
    this.floorPlanRenderer.render();
    
    // Update summary counts
    this.updateSummaryCounts(devices);
  }

  filterDevicesByRoom(roomId) {
    const allDevices = this.deviceManager.getDevices();
    const filteredDevices = allDevices.filter(device => device.room === roomId);
    
    // 部屋名を取得
    const room = this.floorPlanRenderer.floorPlan?.rooms?.find(r => r.id === roomId);
    const roomName = room ? room.name : '';
    
    // デバイス一覧を更新
    this.ui.renderDeviceList(filteredDevices, roomName);
    
    // 選択された部屋をハイライト
    this.highlightRoom(roomId);
    
    // フィルタリング状態を保存
    this.currentFilterRoom = roomId;
    
    // フィルタクリアボタンを表示
    this.showFilterClearButton();
  }

  highlightRoom(roomId) {
    // SVG内の部屋をハイライト
    const svg = document.querySelector('#floor-plan svg');
    if (!svg) return;
    
    // すべての部屋のハイライトを解除
    svg.querySelectorAll('.room-rect').forEach(rect => {
      rect.setAttribute('fill', '#FAFAFA');
      rect.setAttribute('stroke-width', '0.5');
    });
    
    // 選択された部屋をハイライト
    const roomGroup = svg.querySelector(`g[data-room-id="${roomId}"]`);
    if (roomGroup) {
      const roomRect = roomGroup.querySelector('.room-rect');
      if (roomRect) {
        roomRect.setAttribute('fill', '#E3F2FD');
        roomRect.setAttribute('stroke', '#3b82f6');
        roomRect.setAttribute('stroke-width', '1.5');
      }
    }
  }

  showFilterClearButton() {
    // 既存のボタンを削除
    const existingBtn = document.getElementById('clear-filter-btn');
    if (existingBtn) {
      existingBtn.remove();
    }
    
    // フィルタクリアボタンを追加
    const deviceListHeader = document.querySelector('#device-list').parentElement;
    const clearBtn = document.createElement('button');
    clearBtn.id = 'clear-filter-btn';
    clearBtn.className = 'text-sm text-homtune-secondary hover:text-homtune-accent border border-homtune-border px-3 py-1 rounded-sm transition-colors mt-2';
    clearBtn.textContent = 'フィルタをクリア';
    clearBtn.addEventListener('click', () => {
      this.clearRoomFilter();
    });
    
    // ボタンを挿入
    const deviceList = document.getElementById('device-list');
    deviceList.parentElement.insertBefore(clearBtn, deviceList);
  }

  clearRoomFilter() {
    // すべてのデバイスを表示
    const allDevices = this.deviceManager.getDevices();
    this.ui.renderDeviceList(allDevices);
    
    // ハイライトを解除
    const svg = document.querySelector('#floor-plan svg');
    if (svg) {
      svg.querySelectorAll('.room-rect').forEach(rect => {
        const roomGroup = rect.closest('g[data-room-id]');
        if (roomGroup) {
          const roomId = roomGroup.getAttribute('data-room-id');
          const room = this.floorPlanRenderer.floorPlan?.rooms?.find(r => r.id === roomId);
          rect.setAttribute('fill', room?.color || '#FAFAFA');
          rect.setAttribute('stroke', room?.borderColor || '#E0E0E0');
          rect.setAttribute('stroke-width', '0.5');
        }
      });
    }
    
    // フィルタクリアボタンを削除
    const clearBtn = document.getElementById('clear-filter-btn');
    if (clearBtn) {
      clearBtn.remove();
    }
    
    this.currentFilterRoom = null;
  }

  updateSummaryCounts(devices) {
    let alertCount = 0;
    let maintenanceCount = 0;
    
    devices.forEach(device => {
      if (device.maintenance?.alerts) {
        const highPriorityAlerts = device.maintenance.alerts.filter(
          alert => alert.priority === 'high' || alert.priority === 'medium'
        );
        alertCount += highPriorityAlerts.length;
      }
      
      if (device.maintenance?.nextMaintenance) {
        const nextDate = new Date(device.maintenance.nextMaintenance);
        const today = new Date();
        if (nextDate <= new Date(today.getTime() + 30 * 24 * 60 * 60 * 1000)) {
          maintenanceCount++;
        }
      }
    });
    
    document.getElementById('alert-count').textContent = alertCount;
    document.getElementById('maintenance-count').textContent = maintenanceCount;
    document.getElementById('device-count').textContent = devices.length;
  }
}

// Start app when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new App();
  });
} else {
  new App();
}
