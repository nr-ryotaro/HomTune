export class FloorPlanRenderer {
  constructor() {
    this.floorPlan = null;
    this.devices = [];
    this.onRoomClick = null; // 部屋クリック時のコールバック
  }

  setFloorPlan(floorPlan) {
    this.floorPlan = floorPlan;
  }

  setDevices(devices) {
    this.devices = devices;
  }

  setOnRoomClick(callback) {
    this.onRoomClick = callback;
  }

  // 部屋のデバイス数を取得
  getDeviceCountForRoom(roomId) {
    return this.devices.filter(device => device.room === roomId).length;
  }

  render() {
    const container = document.getElementById('floor-plan');
    if (!container || !this.floorPlan) return;

    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('width', '100%');
    svg.setAttribute('height', '100%');
    svg.setAttribute('viewBox', `0 0 ${this.floorPlan.width || 800} ${this.floorPlan.height || 700}`);
    svg.style.border = 'none';

    // Render rooms
    this.floorPlan.rooms.forEach(room => {
      const roomGroup = document.createElementNS('http://www.w3.org/2000/svg', 'g');
      roomGroup.setAttribute('data-room-id', room.id);
      roomGroup.style.cursor = 'pointer';
      
      // 部屋のデバイス数を取得
      const deviceCount = this.getDeviceCountForRoom(room.id);

      // Room rectangle (クリック可能)
      const roomRect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
      roomRect.setAttribute('x', room.coordinates.x);
      roomRect.setAttribute('y', room.coordinates.y);
      roomRect.setAttribute('width', room.coordinates.width);
      roomRect.setAttribute('height', room.coordinates.height);
      roomRect.setAttribute('fill', room.color || '#FAFAFA');
      roomRect.setAttribute('stroke', room.borderColor || '#E0E0E0');
      roomRect.setAttribute('stroke-width', '0.5');
      roomRect.classList.add('room-rect', 'room-clickable');
      roomRect.style.transition = 'all 0.2s';
      
      // ホバー効果
      roomRect.addEventListener('mouseenter', () => {
        roomRect.setAttribute('fill', '#F0F0F0');
        roomRect.setAttribute('stroke-width', '1');
      });
      roomRect.addEventListener('mouseleave', () => {
        roomRect.setAttribute('fill', room.color || '#FAFAFA');
        roomRect.setAttribute('stroke-width', '0.5');
      });
      
      // クリックイベント
      roomRect.addEventListener('click', () => {
        if (this.onRoomClick) {
          this.onRoomClick(room.id);
        }
      });
      
      // タッチイベント（モバイル対応）
      roomRect.addEventListener('touchend', (e) => {
        e.preventDefault();
        if (this.onRoomClick) {
          this.onRoomClick(room.id);
        }
      });
      
      roomGroup.appendChild(roomRect);

      // Room label
      const roomLabel = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      roomLabel.setAttribute('x', room.coordinates.x + 10);
      roomLabel.setAttribute('y', room.coordinates.y + 20);
      roomLabel.setAttribute('font-size', '12');
      roomLabel.setAttribute('fill', '#666');
      roomLabel.setAttribute('font-family', 'sans-serif');
      roomLabel.setAttribute('font-weight', '500');
      roomLabel.textContent = room.name;
      roomGroup.appendChild(roomLabel);

      // デバイス数バッジ
      if (deviceCount > 0) {
        const countBadge = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        const badgeX = room.coordinates.x + room.coordinates.width - 25;
        const badgeY = room.coordinates.y + 20;
        countBadge.setAttribute('cx', badgeX);
        countBadge.setAttribute('cy', badgeY);
        countBadge.setAttribute('r', '12');
        countBadge.setAttribute('fill', '#3b82f6');
        countBadge.setAttribute('stroke', '#ffffff');
        countBadge.setAttribute('stroke-width', '1.5');
        roomGroup.appendChild(countBadge);

        const countText = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        countText.setAttribute('x', badgeX);
        countText.setAttribute('y', badgeY + 4);
        countText.setAttribute('font-size', '10');
        countText.setAttribute('fill', '#ffffff');
        countText.setAttribute('font-family', 'sans-serif');
        countText.setAttribute('font-weight', '600');
        countText.setAttribute('text-anchor', 'middle');
        countText.textContent = deviceCount.toString();
        roomGroup.appendChild(countText);
      }

      // Render devices in room
      if (room.devices) {
        room.devices.forEach(devicePlacement => {
          const device = this.devices.find(d => d.id === devicePlacement.deviceId);
          if (device) {
            this.renderDevice(roomGroup, devicePlacement, device);
          }
        });
      }

      svg.appendChild(roomGroup);
    });

    container.innerHTML = '';
    container.appendChild(svg);
  }

  renderDevice(parent, placement, device) {
    const x = placement.x;
    const y = placement.y;

    // Device circle/icon
    const deviceCircle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
    deviceCircle.setAttribute('cx', x);
    deviceCircle.setAttribute('cy', y);
    deviceCircle.setAttribute('r', '8');
    
    // Color based on maintenance status
    const hasHighPriorityAlert = device.maintenance?.alerts?.some(a => a.priority === 'high');
    if (hasHighPriorityAlert) {
      deviceCircle.setAttribute('fill', '#ef4444');
      deviceCircle.setAttribute('stroke', '#dc2626');
    } else {
      deviceCircle.setAttribute('fill', '#3b82f6');
      deviceCircle.setAttribute('stroke', '#2563eb');
    }
    deviceCircle.setAttribute('stroke-width', '1');
    deviceCircle.classList.add('device-icon');
    parent.appendChild(deviceCircle);

    // Device label
    const deviceLabel = document.createElementNS('http://www.w3.org/2000/svg', 'text');
    deviceLabel.setAttribute('x', x);
    deviceLabel.setAttribute('y', y + 20);
    deviceLabel.setAttribute('font-size', '10');
    deviceLabel.setAttribute('fill', '#333');
    deviceLabel.setAttribute('font-family', 'sans-serif');
    deviceLabel.setAttribute('text-anchor', 'middle');
    deviceLabel.textContent = device.name.split(' ')[0]; // Short name
    parent.appendChild(deviceLabel);
  }
}
