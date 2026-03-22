'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase/client';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    const supabase = createClient();
    const { error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (authError) {
      setError(authError.message);
      setLoading(false);
      return;
    }

    // Resolve role: check carrier_users first, then brokers
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      setError('No se pudo obtener el usuario');
      setLoading(false);
      return;
    }

    const { data: carrierUser } = await supabase
      .from('carrier_users')
      .select('id, carrier_id, role')
      .eq('auth_user_id', user.id)
      .single();

    if (carrierUser) {
      router.push('/dashboard');
      return;
    }

    const { data: broker } = await supabase
      .from('brokers')
      .select('id')
      .eq('auth_user_id', user.id)
      .single();

    if (broker) {
      router.push('/broker');
      return;
    }

    setError('Usuario no tiene permisos de acceso al portal');
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold text-[#1A237E]">
            RuedaSeguro Admin
          </CardTitle>
          <p className="text-sm text-muted-foreground">
            Portal de administración
          </p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="text-sm font-medium" htmlFor="email">
                Correo electrónico
              </label>
              <Input
                id="email"
                type="email"
                placeholder="admin@ejemplo.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div>
              <label className="text-sm font-medium" htmlFor="password">
                Contraseña
              </label>
              <Input
                id="password"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            {error && (
              <p className="text-sm text-red-600">{error}</p>
            )}
            <Button
              type="submit"
              className="w-full bg-[#1A237E] hover:bg-[#3949AB]"
              disabled={loading}
            >
              {loading ? 'Ingresando...' : 'Ingresar'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
