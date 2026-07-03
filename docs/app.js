const display = document.querySelector("#display");
const expression = document.querySelector("#expression");
const keys = document.querySelector(".keys");
const menuButton = document.querySelector("#menuButton");
const markupPanel = document.querySelector("#markupPanel");
const markupInput = document.querySelector("#markupInput");
const historyButton = document.querySelector("#historyButton");
const closeHistoryButton = document.querySelector("#closeHistoryButton");
const historyPanel = document.querySelector("#historyPanel");
const historyList = document.querySelector("#historyList");
const clearButton = document.querySelector("#clearButton");

const state = {
  current: "0",
  queuedNumbers: [],
  queuedOperations: [],
  history: loadHistory(),
  markupPercent: 20,
  lastExpression: "",
  waitingForNumber: false,
};

let lastTouchEnd = 0;
document.addEventListener("touchend", (event) => {
  const now = Date.now();
  if (now - lastTouchEnd <= 300) {
    event.preventDefault();
  }
  lastTouchEnd = now;
}, { passive: false });

menuButton.addEventListener("click", () => {
  markupPanel.hidden = !markupPanel.hidden;
});

historyButton.addEventListener("click", () => {
  historyPanel.hidden = false;
  renderHistory();
});

closeHistoryButton.addEventListener("click", () => {
  historyPanel.hidden = true;
});

markupInput.addEventListener("input", () => {
  state.markupPercent = Number(markupInput.value) || 0;
  render();
});

keys.addEventListener("click", (event) => {
  const button = event.target.closest("button");
  if (!button) return;

  if (button.dataset.digit) inputDigit(button.dataset.digit);
  if (button.dataset.operation) inputOperation(button.dataset.operation);
  if (button.dataset.action === "decimal") inputDecimal();
  if (button.dataset.action === "all-clear") allClear();
  if (button.dataset.action === "backspace") backspace();
  if (button.dataset.action === "percent") percent();
  if (button.dataset.action === "sign") toggleSign();
  if (button.dataset.action === "equals") evaluate();

  render();
});

function inputDigit(digit) {
  if (state.lastExpression && state.waitingForNumber) {
    state.current = "0";
    state.lastExpression = "";
  }

  if (state.waitingForNumber || state.current === "0" || state.current === "") {
    state.current = digit;
    state.waitingForNumber = false;
    return;
  }

  state.current += digit;
}

function inputDecimal() {
  if (state.lastExpression && state.waitingForNumber) {
    state.current = "0";
    state.lastExpression = "";
  }

  if (state.waitingForNumber) {
    state.current = "0.";
    state.waitingForNumber = false;
    return;
  }

  if (!state.current.includes(".")) {
    state.current += ".";
  }
}

function inputOperation(operation) {
  if (state.lastExpression && state.waitingForNumber) {
    state.queuedNumbers.push(parseCurrent());
    state.queuedOperations.push(operation);
    state.lastExpression = "";
    return;
  }

  if (state.waitingForNumber && state.queuedOperations.length > 0) {
    state.queuedOperations[state.queuedOperations.length - 1] = operation;
    return;
  }

  if (state.current === "") return;

  state.queuedNumbers.push(parseCurrent());
  state.queuedOperations.push(operation);
  state.waitingForNumber = true;
}

function evaluate() {
  if (state.queuedOperations.length === 0 || state.waitingForNumber || state.current === "") return;

  const numbers = [...state.queuedNumbers, parseCurrent()];
  let subtotal = numbers[0];

  state.queuedOperations.forEach((operation, index) => {
    const next = numbers[index + 1];

    if (operation === "+") subtotal += next;
    if (operation === "-") subtotal -= next;
    if (operation === "x") subtotal *= next;
    if (operation === "/") subtotal /= next;
  });

  const total = Math.round(subtotal + subtotal * (state.markupPercent / 100));
  const expressionText = buildExpression();

  state.current = formatWhole(total);
  state.lastExpression = expressionText;
  state.history.unshift({
    expression: `${expressionText} + ${formatWhole(state.markupPercent)}%`,
    result: state.current,
  });
  state.history = state.history.slice(0, 4);
  saveHistory();
  state.queuedNumbers = [];
  state.queuedOperations = [];
  state.waitingForNumber = true;
}

function allClear() {
  state.current = "0";
  state.queuedNumbers = [];
  state.queuedOperations = [];
  state.lastExpression = "";
  state.waitingForNumber = false;
}

function backspace() {
  if (state.lastExpression && state.waitingForNumber) {
    state.lastExpression = "";
    state.current = "";
    state.waitingForNumber = false;
    return;
  }

  if (state.waitingForNumber) {
    state.queuedOperations.pop();
    const previousNumber = state.queuedNumbers.pop();

    if (previousNumber !== undefined) {
      state.current = String(previousNumber);
      state.waitingForNumber = false;
    }

    return;
  }

  if (state.current.length <= 1 || (state.current.length === 2 && state.current.startsWith("-"))) {
    if (state.queuedOperations.length > 0) {
      state.queuedOperations.pop();
      const previousNumber = state.queuedNumbers.pop();
      state.current = previousNumber === undefined ? "" : String(previousNumber);
      state.waitingForNumber = false;
      return;
    }

    state.current = "";
    return;
  }

  state.current = state.current.slice(0, -1);
}

function percent() {
  state.current = format(parseCurrent() / 100);
}

function toggleSign() {
  if (state.current === "" || state.current === "0") return;
  state.current = state.current.startsWith("-")
    ? state.current.slice(1)
    : `-${state.current}`;
}

function buildExpression() {
  const parts = [];

  state.queuedNumbers.forEach((number, index) => {
    parts.push(format(number));
    if (state.queuedOperations[index]) {
      parts.push(displayOperation(state.queuedOperations[index]));
    }
  });

  if (!state.waitingForNumber && state.queuedOperations.length > 0) {
    if (state.current === "") return parts.join(" ");
    parts.push(state.current);
  }

  return parts.join("");
}

function format(value) {
  return Number(value).toLocaleString("en-US", {
    maximumFractionDigits: 8,
  });
}

function formatWhole(value) {
  return Math.round(Number(value)).toLocaleString("en-US", {
    maximumFractionDigits: 0,
  });
}

function parseCurrent() {
  return Number(String(state.current).replaceAll(",", ""));
}

function render() {
  const activeExpression = buildExpression();
  const displayText = state.lastExpression ? state.current : activeExpression || state.current || "0";

  expression.textContent = state.lastExpression;
  display.textContent = displayText;
  display.style.fontSize = displayText.length > 9 ? "clamp(46px, 14vw, 82px)" : "";
  expression.style.visibility = state.lastExpression ? "visible" : "hidden";
  clearButton.textContent = (state.lastExpression && state.waitingForNumber)
    || (state.current === "0" && state.queuedOperations.length === 0)
    ? "AC"
    : "C";
  renderHistory();

  document.querySelectorAll("[data-operation]").forEach((button) => {
    const selected = state.waitingForNumber
      && state.queuedOperations[state.queuedOperations.length - 1] === button.dataset.operation;
    button.classList.toggle("selected", selected);
  });
}

function displayOperation(operation) {
  if (operation === "/") return "\u00f7";
  if (operation === "x") return "\u00d7";
  if (operation === "-") return "-";
  return operation;
}

function renderHistory() {
  if (state.history.length === 0) {
    historyList.innerHTML = `<div class="history-empty">No calculations yet</div>`;
    return;
  }

  historyList.innerHTML = state.history
    .map((entry) => `
      <div class="history-item">
        <div class="history-expression">${entry.expression}</div>
        <div class="history-result">${entry.result}</div>
      </div>
    `)
    .join("");
}

function loadHistory() {
  try {
    return JSON.parse(localStorage.getItem("calculatorHistory")) || [];
  } catch {
    return [];
  }
}

function saveHistory() {
  localStorage.setItem("calculatorHistory", JSON.stringify(state.history));
}

render();
