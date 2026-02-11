import { Switch, Route } from "wouter"
import Landing from "./pages/Landing"
import IncomingCall from "./pages/IncomingCall"
import CallCode from "./pages/CallCode"
import Dialer from "./pages/Dialer"
import CallAna from "./pages/CallAna"
import PhoneNotification from "./pages/PhoneNotification"
import Chat from "./pages/Chat"
import Checkout from "./pages/Checkout"
import TikTokFeed from "./pages/TikTokFeed"
import TikTokProfile from "./pages/TikTokProfile"

function App() {
  return (
    <Switch>
      <Route path="/" component={Landing} />
      <Route path="/ligacao" component={IncomingCall} />
      <Route path="/ligacao/code" component={CallCode} />
      <Route path="/discar" component={Dialer} />
      <Route path="/ligacao/ana" component={CallAna} />
      <Route path="/notificacao" component={PhoneNotification} />
      <Route path="/chat" component={Chat} />
      <Route path="/checkout" component={Checkout} />
      <Route path="/tiktok" component={TikTokFeed} />
      <Route path="/tiktok/perfil" component={TikTokProfile} />

      <Route>
        <div className="min-h-screen flex items-center justify-center bg-[hsl(280,40%,2%)] text-white">
          <h1>Pagina nao encontrada</h1>
        </div>
      </Route>
    </Switch>
  )
}

export default App
