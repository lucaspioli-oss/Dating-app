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

function App() {
  return (
    <Switch>
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

      <Route>
        <div className="min-h-screen flex items-center justify-center bg-[hsl(280,40%,2%)] text-white">
          <h1>Pagina nao encontrada</h1>
        </div>
      </Route>
    </Switch>
  )
}

export default App
