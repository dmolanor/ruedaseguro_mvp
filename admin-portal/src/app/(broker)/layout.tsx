import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';
import { DashboardLayout } from '@/components/dashboard-layout';

export default async function BrokerLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) redirect('/login');

  const { data: broker } = await supabase
    .from('brokers')
    .select('id, full_name')
    .eq('auth_user_id', user.id)
    .single();

  if (!broker) redirect('/login');

  return (
    <DashboardLayout
      role="broker"
      userName={broker.full_name}
      userRole="corredor"
      orgName={broker.full_name}
    >
      {children}
    </DashboardLayout>
  );
}
