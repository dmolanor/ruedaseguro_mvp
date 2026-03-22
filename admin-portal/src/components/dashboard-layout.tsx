'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import {
  LayoutDashboard,
  FileText,
  CreditCard,
  AlertTriangle,
  Briefcase,
  Users,
  MapPin,
  Settings,
  LogOut,
  Menu,
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Sheet, SheetContent } from '@/components/ui/sheet';
import { useState } from 'react';

interface NavItem {
  label: string;
  href: string;
  icon: React.ReactNode;
}

const carrierNav: NavItem[] = [
  { label: 'Dashboard', href: '/dashboard', icon: <LayoutDashboard size={20} /> },
  { label: 'Pólizas', href: '/polizas', icon: <FileText size={20} /> },
  { label: 'Pagos', href: '/pagos', icon: <CreditCard size={20} /> },
  { label: 'Reclamos', href: '/reclamos', icon: <AlertTriangle size={20} /> },
  { label: 'Corredores', href: '/corredores', icon: <Briefcase size={20} /> },
  { label: 'Promotores', href: '/promotores', icon: <Users size={20} /> },
  { label: 'Puntos de Venta', href: '/puntos-de-venta', icon: <MapPin size={20} /> },
  { label: 'Configuración', href: '/configuracion', icon: <Settings size={20} /> },
];

const brokerNav: NavItem[] = [
  { label: 'Mi Panel', href: '/broker', icon: <LayoutDashboard size={20} /> },
  { label: 'Mis Pólizas', href: '/broker/polizas', icon: <FileText size={20} /> },
  { label: 'Mis Promotores', href: '/broker/promotores', icon: <Users size={20} /> },
];

interface DashboardLayoutProps {
  role: 'carrier' | 'broker';
  userName: string;
  userRole: string;
  orgName: string;
  children: React.ReactNode;
}

export function DashboardLayout({
  role,
  userName,
  userRole,
  orgName,
  children,
}: DashboardLayoutProps) {
  const pathname = usePathname();
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const navItems = role === 'carrier' ? carrierNav : brokerNav;

  const handleLogout = async () => {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push('/login');
  };

  const Sidebar = () => (
    <div className="flex flex-col h-full">
      <div className="p-4 border-b">
        <h2 className="text-lg font-bold text-[#1A237E]">RuedaSeguro</h2>
        <p className="text-xs text-muted-foreground truncate">{orgName}</p>
      </div>
      <nav className="flex-1 p-2 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={() => setOpen(false)}
              className={`flex items-center gap-3 px-3 py-2 rounded-md text-sm transition-colors ${
                isActive
                  ? 'bg-[#1A237E] text-white'
                  : 'text-slate-700 hover:bg-slate-100'
              }`}
            >
              {item.icon}
              {item.label}
            </Link>
          );
        })}
      </nav>
      <div className="p-4 border-t">
        <Button
          variant="ghost"
          className="w-full justify-start text-slate-600"
          onClick={handleLogout}
        >
          <LogOut size={18} className="mr-2" />
          Cerrar sesión
        </Button>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen flex bg-slate-50">
      {/* Desktop sidebar */}
      <aside className="hidden md:flex w-64 border-r bg-white flex-col">
        <Sidebar />
      </aside>

      {/* Main content */}
      <div className="flex-1 flex flex-col">
        {/* Header */}
        <header className="h-14 border-b bg-white flex items-center justify-between px-4">
          <div className="flex items-center gap-3">
            {/* Mobile hamburger */}
            <Button
              variant="ghost"
              size="icon"
              className="md:hidden"
              onClick={() => setOpen(true)}
            >
              <Menu size={20} />
            </Button>
            <Sheet open={open} onOpenChange={setOpen}>
              <SheetContent side="left" className="w-64 p-0">
                <Sidebar />
              </SheetContent>
            </Sheet>
            <span className="text-sm font-medium text-slate-700 hidden sm:inline">
              {orgName}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <span className="text-sm text-slate-600">{userName}</span>
            <Badge variant="secondary" className="text-xs capitalize">
              {userRole}
            </Badge>
          </div>
        </header>

        {/* Page content */}
        <main className="flex-1 p-6">{children}</main>
      </div>
    </div>
  );
}
