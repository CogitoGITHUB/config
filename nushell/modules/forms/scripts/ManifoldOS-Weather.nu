# =============================================================================
# ManifoldOS — Weather
# Uses wttr.in — no API key required
# Default location: Galați, România
# =============================================================================

const WEATHER_LOCATION = "Galati,Romania"

def get-weather-emoji [condition: string] {
    match ($condition | str downcase) {
        "sunny" | "clear"                          => "☀️"
        "partly cloudy"                             => "🌤️"
        "cloudy" | "overcast"                       => "☁️"
        "mist" | "fog" | "freezing fog"             => "🌫️"
        "light rain" | "light rain shower"
        | "light drizzle" | "patchy light rain"     => "🌦️"
        "moderate rain" | "heavy rain"
        | "rain" | "drizzle" | "rain shower"
        | "heavy rain shower" | "torrential rain"   => "☔"
        "snow" | "light snow" | "heavy snow"
        | "blizzard" | "patchy snow"                => "❄️"
        "sleet" | "ice pellets"                     => "🌨️"
        "thunder" | "thunderstorm"
        | "patchy rain with thunder"
        | "thundery outbreaks in nearby"            => "⚡"
        "tornado"                                   => "🌀"
        "blowing snow" | "freezing drizzle"         => "🌬️"
        _                                      => "🌡️"
    }
}

def fetch-wttr [location: string] {
    let url = $"https://wttr.in/($location)?format=j1"
    try {
        http get $url | from json
    } catch {
        null
    }
}

def format-day [day: record, label: string] {
    let condition = ($day.hourly | get 4? | default ($day.hourly | last) | get weatherDesc | get 0 | get value)
    let emoji     = (get-weather-emoji $condition)
    let high      = ($day.maxtempC | into int)
    let low       = ($day.mintempC | into int)
    let date      = $day.date
    $"($label)  ($date)  ($emoji) ($condition)  ↑($high)°C ↓($low)°C"
}

# Show current weather and 3-day forecast for Galați, România
export def ManifoldOS-Weather [
    --location(-l): string  # Override location (default: Galați, România)
    --celsius(-c)           # Show in Celsius (default)
    --fahrenheit(-f)        # Show in Fahrenheit
] {
    let loc = if ($location | is-empty) { $WEATHER_LOCATION } else { $location }
    let data = (fetch-wttr ($loc | url encode))

    if $data == null {
        print ""
        print $"(ansi red_bold)🌹 MANIFOLD // WEATHER 🌹(ansi reset)"
        print $"(ansi grey)  Could not reach wttr.in — check network.(ansi reset)"
        print ""
        return
    }

    let current   = $data.current_condition.0
    let use_f     = $fahrenheit
    let temp      = if $use_f { $"($current.temp_F)°F" } else { $"($current.temp_C)°C" }
    let feels     = if $use_f { $"($current.FeelsLikeF)°F" } else { $"($current.FeelsLikeC)°C" }
    let condition = ($current.weatherDesc.0.value)
    let emoji     = (get-weather-emoji $condition)
    let humidity  = $current.humidity
    let wind_kmph = $current.windspeedKmph
    let wind_dir  = $current.winddir16Point
    let visibility = $current.visibility
    let uv        = $current.uvIndex

    let day0 = (format-day ($data.weather.0) "today    ")
    let day1 = (format-day ($data.weather.1) "tomorrow ")
    let day2 = (format-day ($data.weather.2) "day 3    ")

    print -n "\e[2J\e[H"
    print ""
    print $"(ansi red_bold)🌹 MANIFOLD // WEATHER 🌹(ansi reset)"
    print $"(ansi grey)  ($loc)(ansi reset)"
    print ""
    print $"(ansi red_bold)  NOW(ansi reset)"
    print $"(ansi grey)  condition(ansi reset)   ($emoji) ($condition)"
    print $"(ansi grey)  temperature(ansi reset) ($temp)  feels like ($feels)"
    print $"(ansi grey)  humidity(ansi reset)    ($humidity)%"
    print $"(ansi grey)  wind(ansi reset)        ($wind_kmph) km/h ($wind_dir)"
    print $"(ansi grey)  visibility(ansi reset)  ($visibility) km"
    print $"(ansi grey)  uv index(ansi reset)    ($uv)"
    print ""
    print $"(ansi red_bold)  FORECAST(ansi reset)"
    print $"(ansi grey)  ($day0)(ansi reset)"
    print $"(ansi grey)  ($day1)(ansi reset)"
    print $"(ansi grey)  ($day2)(ansi reset)"
    print ""
}