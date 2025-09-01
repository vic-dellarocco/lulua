--------------
-- Entry point for loading all PL libraries only on demand, into the global space.
-- Requiring 'pl' means that whenever a module is implicitly accessed
-- (e.g. `utils.split`)
-- then that module is dynamically loaded. The submodules are all brought into
-- the global space.
--Updated to use @{pl.import_into}
-- @module pl
-- require'pl.import_into'(_G)--madness.

require'pl.import_into'(penlight)--VV

--VV: Causes error: "variable '__hide' is not declared": so don't do this:
if rawget(_G,'PENLIGHT_STRICT') then require 'pl.strict' end
