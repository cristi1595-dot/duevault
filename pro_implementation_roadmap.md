# Roadmap Implementare DueVault PRO (Pay-to-Play)

Acest document descrie pașii necesari pentru a transforma DueVault într-o aplicație premium, unde accesul la baza de date este permis doar utilizatorilor logați care au efectuat o plată unică.

## 1. Infrastructura de Plăți
Pentru a verifica dacă un utilizator a plătit, vom folosi:
*   **Google Play Billing Library** (sau un serviciu precum **RevenueCat** pentru o gestionare mai simplă a statusului de abonat/cumpărător pe mai multe platforme).
*   **Serviciu de Status**: Un `proStatusProvider` în Riverpod care să interogheze magazinul de aplicații la pornire.

## 2. Logică de acces (The Gatekeeper)
În `lib/main.dart`, vom modifica structura de navigare pentru a introduce o barieră:

```dart
// Exemplu logică Gatekeeper
final user = ref.watch(authStateProvider).value;
final isPro = ref.watch(proStatusProvider).value ?? false;

if (user == null) {
  return const LoginScreen(); // Forțează logarea
}

if (!isPro) {
  return const UpgradeProScreen(); // Afișează beneficiile și butonul de cumpărare
}

return const MainNavigation(); // Acces permis la Vault
```

## 3. Securizarea Bazei de Date (Isar Encryption)
Pentru a ne asigura că „doar contul care a plătit are acces”, vom folosi UID-ul Firebase pentru a cripta baza de date:

1.  La logare, obținem `user.uid`.
2.  Folosim acest UID (trecut printr-o funcție hash) ca cheie de criptare (`encryptionKey`) pentru Isar.
3.  Dacă un alt cont încearcă să deschidă fișierul bazei de date, acesta va apărea ca fiind corupt/ilizibil.

## 4. Migrarea datelor din Guest
Pentru a nu pierde utilizatorii care au testat aplicația ca Guest:
*   În momentul plății/logării, declanșăm funcția existentă `migrateGuestData(newUid)`.
*   După migrare, ștergem profilul local anonim și activăm sincronizarea Cloud (Firestore) pentru noul cont Pro.

## 5. Experiența Utilizatorului (UX)
*   **UpgradeProScreen**: Un ecran premium care să explice că datele lor sunt acum salvate în siguranță pe viață în Cloud.
*   **Restore Purchases**: Un buton obligatoriu pentru utilizatorii care și-au schimbat telefonul, pentru a-și recupera accesul instantaneu.

---
**Notă:** Implementarea acestui plan necesită configurarea prealabilă a produsului „Pro Upgrade” în Google Play Console.
