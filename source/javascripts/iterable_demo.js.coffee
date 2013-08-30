#= require application
#= require d3

$(document).ready ->
    [updateQueue, resetQueue] = do ->
        abs_width  = 490
        abs_height = 180
        debugging = false

        max = (x, y) -> if x > y then x else y
        min = (x, y) -> if x < y then x else y
        confine = (n, infimum, supremum) ->
            min (max n, infimum), supremum

        colors = d3.scale.category20()

        duration = 1000
        standard_delay = duration / 5

        updateData = (parcel) ->
            # Should modify selection (svg) width and height here
            w = 40
            font_factor = 2 / 3

            # Add new objects (array elements) to be referenced elsewhere
            catalogue = []

            for pkg in parcel
                catalogue = catalogue.concat pkg['obj']

            elems = d3.select('#assets defs')
                .selectAll('.elem')
                # Need to ensure the following line isn't
                # making tons of duplicate entries
                .data(catalogue, (d) -> d)
                .enter()
                .append('svg')
                .attr('id', (d) -> "iterable_elem_#{d}")
                .classed('elem', true)
                .attr('x', 0)
                .attr('y', 0)
                .attr('width', w)
                .attr('height', w)

            elems.append('rect')
                .attr('x', 0)
                .attr('y', 0)
                .attr('width', '100%')
                .attr('height', '100%')
                .attr('fill', (d) -> colors d)

            elems.append('text')
                .attr('x', '50%')
                .attr('y', '75%')
                .attr('text-anchor', 'middle')
                .attr('fill', 'white')
                .attr('font-size', w * font_factor)
                .attr('font-family', 'Cabin, sans-serif')
                .attr('font-style', 'bold')
                .text((d) -> d)

            # Update actual charts
            d3.select('#iterable_demo')
                .classed('one-child', -> parcel.length == 1)
                .classed('not-one-child', -> parcel.length != 1)
                .selectAll('.chart')
                .data(parcel, (d) -> d['name'])
                .call(charts)
                .select('.methods')
                .selectAll('.method')
                .data((d) -> d['methods'])
                .call(methods)

        charts = (selection) ->
            enteror = selection
                .enter()
                .append('figure')
                .classed('chart', true)

            enteror.append('figure-caption').append('h2').text ({ name }) -> name

            selection.exit().remove()

            enteror
                .append('figure')
                .classed('demo_wrapper', true)
                .append('svg')
                .classed('demo_object', true)

            enteror
                .append('figure')
                .classed('methods', true)

            selection
                .select('.demo_object')
                .each demo_object

        demo_object = (datar) ->
            selection = d3.select @
            datar = datar['obj']

            # Should modify selection (svg) width and height here
            # w = abs_width / datar.length
            # w = abs_width / 15
            w = 40
            font_factor = 2 / 3

            main_transition = selection
                .transition()
                .duration(duration / 2)
                .delay(standard_delay)
                .attr('height', w)

            x = d3.scale
                .ordinal()
                .domain(datar)
                .rangeBands([0, min abs_width, w * datar.length])

            joiner = selection
                .selectAll('svg.mover')
                .data(datar, (d) -> d)

            joiner
                .enter()
                .append('svg')
                .classed('mover', true)
                .each((d) ->
                    d3.select(@).classed("iterable_elem_#{d}", true))
                .attr('x', 0)
                .attr('y', 0)
                .attr('width', w)
                .attr('height', w)
                .append('use')
                .attr('xlink:href', (d) -> "#iterable_elem_#{d}")

            joiner.order()

            group_transition = main_transition
                .selectAll('svg.mover')
                .transition()
                .attr('x',  (d) -> x d)
                .attr('y', 0)

            joiner.exit()
                .transition()
                .duration(duration / 5)
                .delay(standard_delay)
                .ease('quad-in')
                .attr('y', 750)
                .remove()

        methods_helper = (orig_selection, entered_selection, name) ->
            entered_selection
                .append('span')
                .classed(name, true)
                .classed('is-empty', (d) -> not d[name]?)
                .text((d) -> d[name])

            orig_selection
                .select("span.#{name}")
                .classed('is-empty', (d) -> not d[name]?)
                .text((d) -> "#{d[name]}")

        methods = (selection) ->
            # Suuuuper messy right now!
            # Ho no!
            # So bad, sad, et al.
            yield_width = '40px'

            selection.exit()
                .transition()
                .duration(duration / 10)
                .remove()

            props = ['name', 'args', 'block', 'yield', 'result']

            meths = selection.enter()
                .append('div')
                .classed('method', true)

            methods_helper selection, meths, name for name in props[0..1]

            meths
                .append('span')
                .classed('block', true)
                .classed('is-empty', (d) -> not d['block']?)
                .html ({ block: out }) ->
                    if out?.match /\n/
                        out = out.replace /\n/, '<br><pre class="code">'
                        out += '</pre>'
                    out


            selection
                .select("span.#{'block'}")
                .classed('is-empty', (d) -> not d['block']?)
                .html ({ block: out }) ->
                    if out?.match /\n/
                        out = out.replace /\n/, '<br><pre class="code">'
                        out += '</pre>'
                    out

            meths
                .append('figure')
                .classed('is-empty', (d) -> not d.yield?)
                .classed('yield', true)
                .append('svg')
                .attr('height', yield_width)
                .attr('width', yield_width)
                .classed('yield', true)

            meths.select('figure.yield')
                .append('figcaption')
                .text 'item yielded'

            methods_helper selection, meths, 'result'

            yielder = selection
                .select('figure.yield')
                .classed('is-empty', (d) -> not d.yield?)
                .select('svg.yield')
                .selectAll('use')
                .data((({ yield: yielded }) -> [yielded]), (d) -> d)

            yielder.exit().remove()

            yielder.enter()
                .append('use')
                .attr('xlink:href', (d) -> "#iterable_elem_#{d}")
                .attr('x', 0)
                .attr('y', 0)
                .each (d) ->
                    $(@).parents('.chart')
                        .find(".iterable_elem_#{d}")
                        # Is there a more elegant 'flash-
                        # this-element' method?
                        .toggle('visible')
                        .toggle('visible')

        queue = []

        resetQueue = -> queue = [ queue[0] ] if queue.length

        updateQueue = (parcel) ->
            queue.unshift parcel unless queue[0] == parcel

        setInterval((-> updateData queue.pop() if queue.length),
            duration * 2)

        [updateQueue, resetQueue]


    window.AppRoutes ?= {}
    window.AppRoutes.update = updateQueue
    window.AppRoutes.reset  = resetQueue
