# =============================================================================
# Visualizzazione di serie temporali con annotazioni delle rotture di metodo
# =============================================================================

# 1. Costante: palette Okabe-Ito (CVD-safe) ----------------------------------

.okabe_ito <- c(
  "#E69F00",
  "#56B4E9",
  "#009E73",
  "#F0E442",
  "#0072B2",
  "#D55E00",
  "#CC79A7",
  "#000000"
)

# 2. Funzione principale -----------------------------------------------------

#' Disegna una timeline con eventuali annotazioni di rotture di metodo
#'
#' Funzione generica per visualizzare una serie temporale long. Pensata per i
#' tre dataset del package ma applicabile a qualunque `data.frame` con una
#' colonna data e una colonna valore. Le rotture di metodo (per i dati GOL
#' nel 2025) si attivano passando un data frame al parametro `ruptures`;
#' tipicamente `gol_method_ruptures`.
#'
#' @param data Un `data.frame` o `data.table` in formato long con almeno una
#'   colonna data e una colonna numerica.
#' @param x Nome (character) della colonna data sull'asse orizzontale.
#'   Default: `"data"`.
#' @param y Nome della colonna numerica da plottare. Default: `"valore"`.
#' @param group Nome opzionale della colonna di raggruppamento (mappata su
#'   colore + tipologia di linea). Lascia `NULL` per una singola serie.
#' @param ruptures Data frame con le rotture da annotare. Deve contenere
#'   colonne `data` (date) ed `evento` (character). Passa
#'   `gol_method_ruptures` per le rotture standard GOL. `NULL` (default) per
#'   nessuna annotazione.
#' @param title,subtitle Titolo e sottotitolo del plot.
#' @param y_label Etichetta dell'asse Y.
#' @param date_breaks Stringa passata a `ggplot2::scale_x_date` (es. `"6 months"`,
#'   `"1 year"`). Default: `"6 months"`.
#' @param smooth Se `TRUE` aggiunge un geom_smooth(method = "loess").
#'
#' @return Un oggetto `ggplot`.
#'
#' @examples
#' \dontrun{
#' library(data.table)
#' serie <- gol_inapp_mensile[
#'   tavola == 2.2 & etichetta == "Emilia-Romagna" &
#'   variabile == "occupati_totale" & percorso == "",
#'   .(data = data_riferimento, valore)
#' ]
#' plot_timeline(serie, ruptures = gol_method_ruptures,
#'               title = "Occupati GOL - Emilia-Romagna",
#'               y_label = "N. occupati")
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_line geom_point geom_vline geom_label
#'   scale_x_date scale_color_manual labs theme_minimal theme element_blank
#'   element_text element_rect element_line element_text
#' @export
plot_timeline <- function(
  data,
  x = "data",
  y = "valore",
  group = NULL,
  ruptures = NULL,
  title = NULL,
  subtitle = NULL,
  y_label = NULL,
  date_breaks = "6 months",
  smooth = FALSE
) {
  stopifnot(is.data.frame(data))
  x_sym <- rlang::sym(x)
  y_sym <- rlang::sym(y)

  if (!is.null(group)) {
    group_sym <- rlang::sym(group)
    p <- ggplot2::ggplot(
      data,
      ggplot2::aes(
        x = !!x_sym,
        y = !!y_sym,
        color = !!group_sym,
        group = !!group_sym
      )
    )
  } else {
    p <- ggplot2::ggplot(
      data,
      ggplot2::aes(x = !!x_sym, y = !!y_sym)
    )
  }

  p <- p +
    ggplot2::geom_line(linewidth = 0.7, na.rm = TRUE) +
    ggplot2::geom_point(size = 1.5, na.rm = TRUE)

  if (isTRUE(smooth)) {
    p <- p +
      ggplot2::geom_smooth(
        method = "loess",
        se = FALSE,
        linewidth = 0.4,
        na.rm = TRUE
      )
  }

  if (!is.null(ruptures)) {
    stopifnot(all(c("data", "evento") %in% names(ruptures)))
    rup <- data.table::as.data.table(ruptures)
    # Stack le etichette per la stessa data (concatenate con newline)
    rup_aggr <- rup[, .(label = paste(evento, collapse = "\n")), by = .(data)]
    p <- p +
      ggplot2::geom_vline(
        data = rup_aggr,
        ggplot2::aes(xintercept = data),
        linetype = "dashed",
        color = "grey40",
        linewidth = 0.4,
        inherit.aes = FALSE
      ) +
      ggplot2::geom_label(
        data = rup_aggr,
        ggplot2::aes(x = data, y = Inf, label = label),
        vjust = 1.05,
        hjust = -0.02,
        size = 2.8,
        color = "grey15",
        fill = "grey95",
        label.padding = ggplot2::unit(0.25, "lines"),
        inherit.aes = FALSE
      )
  }

  p <- p +
    ggplot2::scale_x_date(date_breaks = date_breaks, date_labels = "%Y-%m") +
    ggplot2::scale_color_manual(values = .okabe_ito) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = NULL,
      y = y_label,
      color = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      legend.position = "bottom",
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      plot.title = ggplot2::element_text(face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "grey30")
    )

  p
}
