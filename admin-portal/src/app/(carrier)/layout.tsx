import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { DashboardLayout } from '@/components/dashboard-layout';

export default async function CarrierLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  const { data: carrierUser } = await supabase
    .from('carrier_users')
    .select('id, role, full_name, carrier_id, carriers(name)')
    .eq('auth_user_id', user.id)
    .single();

  if (!carrierUser) redirect('/login');

  const orgName = (carrierUser as Record<string, unknown>).carriers
    ? ((carrierUser as Record<string, unknown>).carriers as Record<string, string>).name
    : 'RuedaSeguro';

  return (
    <DashboardLayout
      role="carrier"
      userName={carrierUser.full_name}
      userRole={carrierUser.role}
      orgName={orgName}
    >
      {children}
    </DashboardLayout>
  );
}
