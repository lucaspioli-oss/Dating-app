import { Switch, Route } from "wouter"
import Landing from "./pages/Landing"
import Quiz from "./pages/Quiz"
import Result from "./pages/Result"
import Sales from "./pages/Sales"
import Sales2 from "./pages/Sales2"
import CheckoutMensal from "./pages/CheckoutMensal"
import CheckoutTrimestral from "./pages/CheckoutTrimestral"
import CheckoutAnual from "./pages/CheckoutAnual"
import Success from "./pages/Success"
import Teste from "./pages/Teste"

// Game Funnel Pages
import GameLanding from "./pages/game/Landing"
import GameIncomingCall from "./pages/game/IncomingCall"
import GameCallCode from "./pages/game/CallCode"
import GameDialer from "./pages/game/Dialer"
import GameCallAna from "./pages/game/CallAna"
import GamePhoneNotification from "./pages/game/PhoneNotification"
import GameChat from "./pages/game/Chat"
import GameCheckout from "./pages/game/Checkout"
import GameTikTokFeed from "./pages/game/TikTokFeed"
import GameTikTokProfile from "./pages/game/TikTokProfile"

function App() {
  return (
    <Switch>
      {/* Funil Original */}
      <Route path="/" component={Landing} />
      <Route path="/quiz" component={Quiz} />
      <Route path="/result" component={Result} />
      <Route path="/sales" component={Sales} />
      <Route path="/sales2" component={Sales2} />
      <Route path="/checkout/mensal" component={CheckoutMensal} />
      <Route path="/checkout/trimestral" component={CheckoutTrimestral} />
      <Route path="/checkout/anual" component={CheckoutAnual} />
      <Route path="/success" component={Success} />
      <Route path="/teste" component={Teste} />

      {/* Funil Game - Ligação */}
      <Route path="/game" component={GameLanding} />
      <Route path="/game/ligacao" component={GameIncomingCall} />
      <Route path="/game/ligacao/code" component={GameCallCode} />
      <Route path="/game/discar" component={GameDialer} />
      <Route path="/game/ligacao/ana" component={GameCallAna} />
      <Route path="/game/notificacao" component={GamePhoneNotification} />
      <Route path="/game/chat" component={GameChat} />
      <Route path="/game/checkout" component={GameCheckout} />
      <Route path="/game/tiktok" component={GameTikTokFeed} />
      <Route path="/game/tiktok/perfil" component={GameTikTokProfile} />

      <Route>
        <div className="min-h-screen flex items-center justify-center bg-[hsl(280,40%,2%)] text-white">
          <h1>Pagina nao encontrada</h1>
        </div>
      </Route>
    </Switch>
  )
}

export default App
