const _moarwick$elm_webpack_starter$Native_Blorgh = {
  readFromLocalStorage: logFoo => logBar => {
  	const val = localStorage.getItem("JWT");
  	if (typeof val === "string") {
        return _elm_lang$core$Maybe$Just(val);
    } else {
		return _elm_lang$core$Maybe$Nothing;
  	}
  },
  storeInLocalStorage: (value) => {
    localStorage.setItem("JWT", value);
    return value;
  }
}