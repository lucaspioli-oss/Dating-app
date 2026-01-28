import { Switch, Route } from "wouter"
import Landing from "./pages/Landing"
import IncomingCall from "./pages/IncomingCall"
import CallCode from "./pages/CallCode"
import Dialer from "./pages/Dialer"
import CallAna from "./pages/CallAna"
import Chat from "./pages/Chat"
import Checkout from "./pages/Checkout"

function App() {
  return (
    <Switch>
      <Route path="/" component={Landing} />
      <Route path="/ligacao" component={IncomingCall} />
      <Route path="/ligacao/code" component={CallCode} />
      <Route path="/discar" component={Dialer} />
      <Route path="/ligacao/ana" component={CallAna} />
      <Route path="/chat" component={Chat} />
      <Route path="/checkout" component={Checkout} />
      <Route>
        <div className="min-h-screen flex items-center justify-center">
          <h1 className="text-2xl text-white/50">Página não encontrada</h1>
        </div>
      </Route>
    </Switch>
  )
}

export default App
