import React, { useEffect, useCallback, createContext, useContext, ReactNode } from 'react';
import { X } from 'lucide-react';
import './Modal.css';

interface ModalContextType {
  openModal: (content: ReactNode, options?: ModalOptions) => string;
  closeModal: (id: string) => void;
  closeAllModals: () => void;
}

interface ModalOptions {
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  closable?: boolean;
  onClose?: () => void;
}

interface ModalState {
  id: string;
  content: ReactNode;
  options: Required<ModalOptions>;
}

const ModalContext = createContext<ModalContextType | null>(null);

export const useModal = () => {
  const context = useContext(ModalContext);
  if (!context) throw new Error('useModal must be used within a ModalProvider');
  return context;
};

interface ModalProviderProps { children: ReactNode; }

export const ModalProvider: React.FC<ModalProviderProps> = ({ children }) => {
  const [modals, setModals] = React.useState<ModalState[]>([]);

  const openModal = useCallback((content: ReactNode, options: ModalOptions = {}) => {
    const id = `modal-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    const modalOptions: Required<ModalOptions> = { size: options.size || 'md', closable: options.closable !== false, onClose: options.onClose || (() => {}) };
    setModals(prev => [...prev, { id, content, options: modalOptions }]);
    return id;
  }, []);

  const closeModal = useCallback((id: string) => {
    setModals(prev => { const modal = prev.find(m => m.id === id); if (modal) modal.options.onClose(); return prev.filter(m => m.id !== id); });
  }, []);

  const closeAllModals = useCallback(() => { setModals(prev => { prev.forEach(m => m.options.onClose()); return []; }); }, []);

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => { if (e.key === 'Escape' && modals.length > 0) { const topModal = modals[modals.length - 1]; if (topModal.options.closable) closeModal(topModal.id); } };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [modals, closeModal]);

  return (
    <ModalContext.Provider value={{ openModal, closeModal, closeAllModals }}>
      {children}
      <div className="modal-portal">
        {modals.map((modal, index) => (
          <ModalOverlay key={modal.id} id={modal.id} content={modal.content} size={modal.options.size} closable={modal.options.closable} onClose={() => closeModal(modal.id)} isTop={index === modals.length - 1} />
        ))}
      </div>
    </ModalContext.Provider>
  );
};

interface ModalOverlayProps { id: string; content: ReactNode; size: ModalOptions['size']; closable: boolean; onClose: () => void; isTop: boolean; }

const ModalOverlay: React.FC<ModalOverlayProps> = ({ id, content, size, closable, onClose, isTop }) => {
  const handleBackdropClick = (e: React.MouseEvent) => { if (e.target === e.currentTarget && closable) onClose(); };
  const sizeClass = { sm: 'modal-sm', md: 'modal-md', lg: 'modal-lg', xl: 'modal-xl', full: 'modal-full' }[size || 'md'];
  return (
    <div className="modal-overlay" onClick={handleBackdropClick} style={{ zIndex: 900 + (isTop ? 10 : 0) }}>
      <div className={`modal-content ${sizeClass}`} role="dialog" aria-modal="true" aria-labelledby={`${id}-title`}>
        {closable && <button className="modal-close" onClick={onClose} aria-label="Cerrar modal"><X width={20} height={20} /></button>}
        <div className="modal-body">{content}</div>
      </div>
    </div>
  );
};

export const Modal: React.FC<{ isOpen: boolean; onClose: () => void; title?: string; children: ReactNode; size?: ModalOptions['size']; closable?: boolean; }> = ({ isOpen, onClose, title, children, size = 'md', closable = true }) => {
  const { openModal, closeModal } = useModal();
  const modalIdRef = React.useRef<string | null>(null);
  useEffect(() => {
    if (isOpen) {
      modalIdRef.current = openModal(
        <>
          {title && <h2 id={`${modalIdRef.current}-title`} className="modal-title">{title}</h2>}
          {children}
        </>,
        { size, closable, onClose }
      );
    } else if (modalIdRef.current) {
      closeModal(modalIdRef.current);
      modalIdRef.current = null;
    }
    return () => {
      if (modalIdRef.current) closeModal(modalIdRef.current);
    };
  }, [isOpen, openModal, closeModal, title, children, size, closable, onClose]);
  return null;
};

export const ConfirmDialog: React.FC<{ isOpen: boolean; onClose: () => void; onConfirm: () => void; title: string; message: string; confirmText?: string; cancelText?: string; variant?: 'danger' | 'primary'; }> = ({ isOpen, onClose, onConfirm, title, message, confirmText = 'Confirmar', cancelText = 'Cancelar', variant = 'primary' }) => {
  const { openModal, closeModal } = useModal();
  const modalIdRef = React.useRef<string | null>(null);
  useEffect(() => {
    if (isOpen) {
      modalIdRef.current = openModal(
        <>
          <h2 id={`${modalIdRef.current}-title`} className="modal-title">{title}</h2>
          <p className="modal-message">{message}</p>
          <div className="modal-actions">
            <button className="btn-secondary" onClick={onClose}>{cancelText}</button>
            <button className={`btn-${variant}`} onClick={() => { onConfirm(); onClose(); }}>{confirmText}</button>
          </div>
        </>,
        { size: 'sm', closable: true, onClose }
      );
    } else if (modalIdRef.current) {
      closeModal(modalIdRef.current);
      modalIdRef.current = null;
    }
  }, [isOpen, openModal, closeModal, title, message, confirmText, cancelText, variant, onConfirm, onClose]);
  return null;
};

export default ModalProvider;
