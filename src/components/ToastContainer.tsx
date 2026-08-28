import React, { useEffect } from 'react';
import { X, CheckCircle, AlertCircle, AlertTriangle, Info } from 'lucide-react';
import { useCanvasStore } from '../stores/canvas-store';
import { useI18n } from '../i18n';
import './ToastContainer.css';

export const ToastContainer: React.FC = () => {
  const { toasts, removeToast } = useCanvasStore();
  const { t } = useI18n();

  useEffect(() => {
    toasts.forEach(toast => {
      if (toast.duration !== 0) {
        const duration = toast.duration ?? 5000;
        setTimeout(() => removeToast(toast.id), duration);
      }
    });
  }, [toasts, removeToast]);

  if (toasts.length === 0) return null;

  const getIcon = (type: string) => {
    switch (type) {
      case 'success': return <CheckCircle size={20} style={{ color: '#22c55e' }} />;
      case 'error': return <AlertCircle size={20} style={{ color: '#ef4444' }} />;
      case 'warning': return <AlertTriangle size={20} style={{ color: '#f59e0b' }} />;
      default: return <Info size={20} style={{ color: '#3b82f6' }} />;
    }
  };

  const getBorderColor = (type: string) => {
    switch (type) {
      case 'success': return '#22c55e';
      case 'error': return '#ef4444';
      case 'warning': return '#f59e0b';
      default: return '#3b82f6';
    }
  };

  return (
    <div className="toast-container" role="region" aria-label={t("toast.notifications")}>
      {toasts.map(toast => (
        <div
          key={toast.id}
          className="toast"
          style={{ borderLeftColor: getBorderColor(toast.type) }}
          role="alert"
        >
          <div className="toast-icon">
            {getIcon(toast.type)}
          </div>
          <div className="toast-content">
            <p className="toast-message">{toast.message}</p>
          </div>
          <button
            className="toast-close"
            onClick={() => removeToast(toast.id)}
            aria-label={t("toast.closeNotification")}
          >
            <X size={16} />
          </button>
          {toast.duration !== 0 && (
            <div 
              className="toast-progress" 
              style={{ 
                backgroundColor: getBorderColor(toast.type),
                animationDuration: `${toast.duration ?? 5000}ms`
              }} 
            />
          )}
        </div>
      ))}
    </div>
  );
};

export default ToastContainer;