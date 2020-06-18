signal_connect((widget) -> cb_nv_changed(widget), b["cobo_nv"], "changed")


for i in lowercase.(nu_names)
    signal_connect((widget) -> cb_cbtn_con_toggled(widget), b["cbtn_" * i], "toggled")
end

for j in ["cobo", "lmt", "w"]
    for i in lowercase.(nu_names)
        signal_connect((widget) -> cb_con_changed(widget), b[j * "_" * i], "changed")
    end
end

signal_connect((widget) -> cb_tb_calc(widget), b["tb_calc"], "clicked")

signal_connect((widget) -> cb_sp_year_min_changed(widget), b["sp_year_min"], "value-changed")
signal_connect((widget) -> cb_sp_year_max_changed(widget), b["sp_year_max"], "value-changed")